# Studio inputs configuration - common for all stations

# Get SRT passphrase for encryption
SRT_PASSPHRASE = environment.get("SRT_PASSPHRASE")

# Note: SILENCE_CONTROL_PATH and is_silence_detection_enabled() are defined in defaults.liq

# Function to create a studio SRT input with silence detection and buffering
def create_studio_input(~id, ~port) =
  # Create SRT input
  studio =
    input.srt(
      id=id,
      port=port,
      mode="listener",
      max=10.0,
      streamid=id,
      enforced_encryption=true,
      passphrase=SRT_PASSPHRASE,
      on_connect=fun () -> log_event(id, "connected"),
      on_disconnect=fun () -> log_event(id, "disconnected")
    )

  # Create version with silence detection and stripping
  studio_with_detect =
    blank.detect(
      id="detect_#{id}",
      max_blank=SILENCE_SWITCH_SECONDS,
      min_noise=AUDIO_VALID_SECONDS,
      fun () ->
        log_event(
          id,
          "silence detected"
        ),
      on_noise=
        fun () ->
          log_event(
            id,
            "audio resumed"
          ),
      studio
    )

  studio_stripped =
    blank.strip(
      id="stripped_#{id}",
      max_blank=SILENCE_SWITCH_SECONDS,
      min_noise=AUDIO_VALID_SECONDS,
      studio_with_detect
    )

  # Use switch to select between stripped version and original
  studio_switchable =
    switch(
      id="switch_silence_#{id}",
      track_sensitive=false,
      [
        ({is_silence_detection_enabled()}, studio_stripped),
        # When silence detection is disabled, use raw studio source
        ({not (is_silence_detection_enabled())}, studio)
      ]
    )

  # Buffer to prevent connection/disconnection latency impact
  buffer(id="buffered_#{id}", fallible=true, studio_switchable)
end

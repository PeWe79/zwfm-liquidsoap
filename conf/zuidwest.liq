# Include default configuration values
%include "lib/defaults.liq"

# Include library configurations
%include "lib/studio_inputs.liq"
%include "lib/stereotool.liq"

# Create the two studio inputs
studio_a = create_studio_input(id="studio_a", port=8888)
studio_b = create_studio_input(id="studio_b", port=9999)

# Combine live inputs and fallback
radio =
  fallback(
    id="radio_prod",
    track_sensitive=false,
    [studio_a, studio_b, emergency_fallback]
  )

# Create processed/unprocessed audio sources
# When StereoTool is enabled (STEREOTOOL_LICENSE_KEY is set), it provides:
# - Audio processing (AGC, compression, limiting, etc.)
# - MicroMPX encoding for FM transmitters (available in StereoTool itself)
# Two audio sources are available:
# - 'radio': Unprocessed audio (direct from studio/fallback)
# - 'radio_processed': Either StereoTool-processed audio (if enabled) or unprocessed audio (if disabled)
radio_processed = create_processed_audio(radio)

# Include output configurations
%include "lib/icecast_outputs.liq"
%include "lib/dab_output.liq"

# Output a high bitrate mp3 stream
output_icecast_stream(
  format=%mp3(bitrate = 192, samplerate = 48000, internal_quality = 0),
  description=
    "Hoge Kwaliteit Stream (192kbit MP3)",
  mount=HIGH_QUALITY_MOUNT,
  source=radio
)

# Output a low bitrate AAC stream
output_icecast_stream(
  format=
    %fdkaac(
      channels = 2,
      samplerate = 48000,
      bitrate = 96,
      afterburner = true,
      aot = 'mpeg4_aac_lc',
      transmux = 'adts',
      sbr_mode = true
    ),
  description=
    "Mobile Stream (96kbit AAC)",
  mount=MOBILE_MOUNT,
  source=radio
)

# Output a high bitrate AAC STL stream
output_icecast_stream(
  format=
    %fdkaac(
      channels = 2,
      samplerate = 48000,
      bitrate = 576,
      afterburner = true,
      aot = 'mpeg4_aac_lc',
      transmux = 'adts',
      sbr_mode = true
    ),
  description=
    "Transport Stream (576kbit AAC)",
  mount=TRANSPORT_MOUNT,
  source=radio
)

# Output to DAB+
output_dab_stream(radio)

# DAB+ output configuration using ODR-AudioEnc
# This library provides a reusable function for DAB+ encoding

# Function to create DAB+ output
# @param source The audio source to encode
def output_dab_stream(source) =
  # Check if DAB+ is configured
  if
    ODR_AUDIOENC_BITRATE != "" and ODR_AUDIOENC_EDI_URL != ""
  then
    log(
      "DAB+ output enabled - Bitrate: #{ODR_AUDIOENC_BITRATE}kbps, EDI: #{
        ODR_AUDIOENC_EDI_URL
      }",
      level=3
    )

    # Create a clock for DAB+ output
    audio_to_dab = mksafe(buffer(source))
    clock.assign_new(id="dab_clock", [audio_to_dab])

    # Build command with optional parameters
    odr_command =
      ref(
        "/bin/odr-audioenc -i - --bitrate=#{ODR_AUDIOENC_BITRATE}"
      )

    # Add PAD configuration if socket is set
    if
      ODR_PADENC_SOCK != ""
    then
      # PAD socket requires PAD to be enabled - default to 58 if not specified
      pad_size = if ODR_PAD_SIZE != "" then ODR_PAD_SIZE else "58" end
      odr_command :=
        "#{odr_command()} --pad=#{pad_size} --pad-socket=#{ODR_PADENC_SOCK}"
    end

    # Add EDI outputs - supports comma-separated list
    edi_urls = string.split(separator=",", ODR_AUDIOENC_EDI_URL)
    list.iter(
      fun (url) ->
        begin
          # Trim whitespace from URL
          trimmed_url = string.trim(url)
          odr_command :=
            "#{odr_command()} --edi=\"#{trimmed_url}\""
        end,
      edi_urls
    )

    # Feed the audio to ODR-AudioEnc
    output.external(
      %wav(channels = 2, samplerate = 48000), odr_command(), audio_to_dab
    )
  else
    log(
      "DAB+ output disabled - ODR_AUDIOENC_BITRATE and/or ODR_AUDIOENC_EDI_URL \
       not configured",
      level=3
    )
  end
end

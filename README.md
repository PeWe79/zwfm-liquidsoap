# liquidsoap-ubuntu
This repository offers an audio streaming solution specifically designed for [ZuidWest FM](https://www.zuidwestfm.nl/) in the Netherlands. Utilizing [Liquidsoap](https://www.liquidsoap.info), it provides internet streaming with a never silent fallback and is able to push MPX to broadcast transmitters using MicroMPX.

## Components:
1. **Liquidsoap**: Serves as the core audio router and transcoder.
2. **Icecast**: A public server for distributing the audio stream.
3. **StereoTool**: An optional component for integrating [MicroMPX](https://www.thimeo.com/micrompx/) with transmitters.

## Scripts:
- **icecast2.sh**: Installs Icecast 2 and offers SSL support through Let's Encrypt/Certbot.
- **install.sh**: Facilitates the installation of Liquidsoap 2.2.2 with fdkaac support and configures it as an auto-start service.

## Configurations:
- **radio.liq**: A ready-to-use Liquidsoap configuration, incorporating StereoTool as MicroMPX encoder (disabled by default).
- **liquidsoap.service**: A systemd service file for managing Liquidsoap.

## Compatibility:
1. Compatible with Ubuntu 22.04 or Debian 12.
2. Supports x86_64 or ARM64 system architectures (e.g., Ampere Altra, Raspberry Pi). Note: ARM compatibility is currently under evaluation.
3. Requires an internet connection for script dependencies.

# MIT License

Copyright 2023 Streekomroep ZuidWest

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
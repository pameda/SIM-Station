# Third-party notices

## SIM Station distribution

SIM Station incorporates the MIT-licensed protocol/model files in `Station/Protocol`
and USB AT implementation in `Sources/CModemBridge` from MaVo,
https://github.com/moluncn/mavo, commit `0443dfdaf8aec086fd76ba2ee9152fd908114524`.
Copyright (c) 2026 MaVo contributors. The complete MIT license is retained in LICENSE.

SIM Station does NOT distribute the optional kernel modules, PCM bridge, or their installers.
No upstream logo or application icon is used. The application icon uses Apple's system symbols.

## Original upstream notices (retained for attribution)

The following is the original MaVo notice. References to a bundled voice runtime
describe MaVo, NOT this SIM Station distribution.

The macOS application and its user-space PCM bridge were written independently.
The following projects were consulted for protocol behavior and test strategy;
their source code is not copied into those components:

- asterisk-chan-quectel, GPL-2.0 (protocol behavior only; no source vendored):
  <https://github.com/IchthysMaranatha/asterisk-chan-quectel>
- Quectel EC2x/EG9x Voice over USB and UAC application note:
  <https://auroraevernet.ru/upload/iblock/f57/xkjhy4olve0k1n8e0z43hq4nk5h604d2.pdf>
- warthog618/sms, MIT:
  <https://github.com/warthog618/sms>
- WWANManager, MIT:
  <https://github.com/patriczeq/WWANManager>
- Blue Robotics Cellphone Modem Manager, MIT:
  <https://github.com/bluerobotics/cellphone-modem-manager>

The optional QDC507 voice runtime bundles two loadable Linux kernel modules
derived from `the-modem-distro/quectel_eg25_kernel`, commit
`82ed00908b3e8efc3ff0de27d2b5a7c0524ecd7f`, under GPL-2.0:

- <https://github.com/the-modem-distro/quectel_eg25_kernel>

The application bundle includes the GPL-2.0 license and a module build report
next to those binaries in `Resources/ModuleVoice`.

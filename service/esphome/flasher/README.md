
## Setup
```
pipenv install --skip-lock

```

## Linux

Serial usb-c to uart/rs232 convertor:
- eshop: https://botland.cz/prevadece-usb-uart-rs232-rs485/20539-konvertor-usb-uart-ttl-pl2303-zasuvka-usb-typu-c-waveshare-20645-5904422381592.html
- product: https://www.waveshare.com/wiki/PL2303_USB_UART_Board_(type_A)


```
#lsusb output identifies the device as Bus 001 Device 016: ID 067b:2303 Prolific Technology, Inc. PL2303 Serial Port

$ lsusb -v -d 067b:2303
bMaxPacketSize0 64
```

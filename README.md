# capacitor-brotherprint - a fork of @rdlabo/capacitor-brotherprint
Capacitor Brother Print is a native Brother Print SDK implementation for iOS & Android. This plugin can use in `QL-820NW` and `QL-800`.

## How to install
```
% npm install @rdlabo/capacitor-brotherprint@git@github.com:rdlabo-team/capacitor-brotherprint.git
```

## How to use

```typescript
import { Plugins } from '@capacitor/core';
const { BrotherPrint } = Plugins;
import { BrotherPrintOptions } from '@rdlabo/capacitor-brotherprint';

@Component({
  selector: 'brother-print',
  templateUrl: 'brother.component.html',
  styleUrls: ['brother.component.scss']
})
export class BrotherComponent {
  constructor() {
    // Success to print
    BrotherPrint.addListener('onPrint', (info) => {
      console.log("onPrint");
    });
    // Failed to communication with printer
    BrotherPrint.addListener('onPrintError', (info) => {
      console.log("onPrintError");
    });
    // Failed to communication with printer
    BrotherPrint.addListener('onPrintFailedCommunication', (info) => {
      console.log("onPrintFailedCommunication");
    });
  }
  print() {
    BrotherPrint.printImage({
      printerType: 'QL-820NW',
      encodedImage: 'base64 removed mime-type', // base64
    } as BrotherPrintOptions)
  }
  printWithNetWork() {
    const wifi = () => new Promise(resolve => {
      BrotherPrint.addListener('onIpAddressAvailable', (info) => {
        resolve(info);
      });
    });

    const ble = () => new Promise(resolve => {
      BrotherPrint.addListener('onBLEAvailable', (info) => {
        resolve(info);
      });
    });
    
    Promise.all([wifi(), ble()]).then((values) => {
      console.log(values);
    });

    const options : BrotherSearchOptions = {
      printerType : "QL-810W"
    }
    BrotherPrint.searchWiFiPrinter(options);
    BrotherPrint.searchBLEPrinter(options);
  } 
}
```

## Installation
```
$ npm install --save @rdlabo/capacitor-brotherprint
```

### Android configuration
In file `android/app/src/main/java/**/**/MainActivity.java`, add the plugin to the initialization list:

```java
import jp.rdlabo.capacitor.plugin.brotherprint.BrotherPrint;

this.init(savedInstanceState, new ArrayList<Class<? extends Plugin>>() {{
    [...]
  add(BrotherPrint.class);
    [...]
}});
```

and download `BrotherPrintLibrary.aar` and put to your android project:
https://support.brother.co.jp/j/s/support/html/mobilesdk/guide/getting-started/getting-started-android.html

### iOS configuration
To configure this plugin for iOS (with network privacy updates added in 14+), you'll need to include permissions for location as well as searching the network. This is explained here: https://developer.apple.com/videos/play/wwdc2020/10110/

The following info.plist entries are required:

Bonjour Services to Allow the Search
```	
<key>NSBonjourServices</key>
<array>
	<string>_pdl-datastream._tcp</string>
	<string>_printer._tcp</string>
	<string>_ipp._tcp</string>
</array>
```

UI Accessory Protocols
```
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.brother.ptcbp</string>
</array>
```

Network Usage Statement
```
<key>NSLocalNetworkUsageDescription</key>
<string>The local network is needed to find printers</string>
```

Location In-Use Statement
```
<key>NSLocationWhenInUseUsageDescription</key>
<string>To use the local network, it's required that you grant permission for location.</string>
```

## Run Demo
以下デモの動かし方です。

```
% cd demo/angular
% npm install && npm run build
% npx cap copy
% npx cap open ios
```

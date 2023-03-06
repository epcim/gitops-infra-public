

## setup

https://help.prusa3d.com/en/article/octoprint-configuration-and-install_2182

## Issues

Printer is disconnected and Octoprint cant connect:
```
test -d /dev/ttyACM0 && rmdir /dev/ttyACM0; usbreset $(lsusb | awk '/Prusa Original Prusa MINI/{print $6}'); microk8s.kubectl delete po -n home $(kubectl get po --selector app.kubernetes.io/name=octoprint -Ao name| sed 's#pod/##');
```



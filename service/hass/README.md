
## add configs

---
```markdown
kustomize edit add configmap home-assistant-automations  [--behavior={create|merge|replace}] --from-file='config/automation/*.yaml'
```
---


## mikrotik

---
```markdown
/user group add name=hass policy=read,api,!local,!telnet,!ssh,!ftp,!reboot,!write,!policy,test,!winbox,!password,!web,!sniff,!sensitive,!romon,!dude,!tikapp;
/user add group=hass name=hass;
/user set password="XXXX" hass;

```
---


## validate

---
```markdown
$(pyenv which hass) --script check_config -c clusters/home/home/hass/config
```
---

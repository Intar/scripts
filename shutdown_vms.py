#!/usr/bin/python


def list_vms(host,passw):
    p1 = subprocess.Popen(["vmware-cmd", "-H", host, "-U", "root", "-P", passw, "-l" ], stdout = subprocess.PIPE).communicate()[0]
    p1 = p1.split("\n")
    n = len(p1)
    p1.pop(n-1)
    p1.pop(0)
    return p1


def list_poweron_vm(command):
    vms = {}
    p1 = subprocess.Popen([command], shell=True, stdout = subprocess.PIPE).communicate()[0]
    p1 = p1.split("\n\n")
    for n in p1:
        m = re.match('^(.*)\n(.*?\n){1,5}\s*\D*\s\D*:\s(.*)',n)
        if m:
            vms[m.group(1)] = m.group(3)
    return vms


def shutdown_vm(vm,connect):  
    for name,path in vm.items():
        command = connect + " \"" + path + "\" stop soft"
        print "Shutdown vm: " + name
        p1 = subprocess.Popen([command], shell=True, stdout = subprocess.PIPE).communicate()[0]
        print p1
        sleep(5)
        if re.match('^Operation.*',p1):
            print "One more try"
            subprocess.Popen([command], shell=True, stdout = subprocess.PIPE).communicate()[0]
        


def shutdown_host(host,passw):
    connect = "vicfg-hostops --server " + host + " --username root --password " + passw + " "
    command_enter_maintaince = connect + "-o enter"
    command_shutdown = connect + "-o shutdown"
    command_exit_maintaince = connect + "-o exit"
    print subprocess.Popen([command_enter_maintaince], shell=True, stdout = subprocess.PIPE).communicate()[0]
    print subprocess.Popen([command_shutdown], shell=True, stdout = subprocess.PIPE).communicate()[0]
    print subprocess.Popen([command_exit_maintaince], shell=True, stdout = subprocess.PIPE).communicate()[0]


import subprocess
import re
from time import sleep
host = "1.1.1.1"
passw = "password"
connect = "vmware-cmd -H " + host + " -U root -P " + passw
list_poweron = "esxcli -s " + host + " -u root -p " + passw + " vm process list"
list = connect + " -l"
vip_vm = {}
#Shutdown list "vip_vm"
shutdown_vm(vip_vm,connect)
sleep(5)
#Shutdown all power on VM's on host
shutdown_vm(list_poweron_vm(list_poweron),connect)
sleep(60)
#Enter maintaince mode, shutdown and exit maintaince mode host
shutdown_host(host,passw)

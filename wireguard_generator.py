import ctypes, sys
import time
import os
from os import listdir
import pathlib
import winreg as wreg

def enable_IP_forwarding():
    key = wreg.OpenKey(wreg.HKEY_LOCAL_MACHINE, r'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 0, wreg.KEY_SET_VALUE)
    wreg.SetValueEx(key, "IPEnableRouter", 1, wreg.REG_DWORD, 1)

def enable_IP_forwarding2():
    key = wreg.OpenKey(wreg.HKEY_LOCAL_MACHINE, r'SOFTWARE\Microsoft\Windows\CurrentVersion\SharedAccess', 0, wreg.KEY_SET_VALUE)
    wreg.SetValueEx(key, "EnableRebootPersistConnection", 1, wreg.REG_DWORD, 1)

def config_generator():

    config_hash={}
    config=None
    #Get the directory contents

    #print(listdir(pathlib.Path(__file__).parent.absolute()))
    #print(pathlib.Path(__file__).parent.absolute())
    #Python changed something....Have to adapt
    #print(os.path.dirname(os.path.realpath(sys.argv[0])))

    #time.sleep(10)
    #exit()

    directory=(os.path.dirname(os.path.realpath(sys.argv[0])))
    #print(directory)

    for file in os.listdir(directory):
        #print(file)
        #Only look inside file and ignore directories
        if os.path.isfile(file):
            if 'support@perimeter81.com' in open(file, encoding='utf8', errors='ignore').read() and not file.endswith('.py'):
                #If above matches, we are pretty certain we've located the config file
                config=file

    if config == None:
        print("You Perimeter81 configuration file was not found. Please download it from your workspace")
        input("Press Enter to continue...")

    f = open(config, 'r')
    lines = f.readlines()

    for line in lines:
        if line.startswith('CONFIG'):
            key = line.split('=', 1)[0]
            value = line.split('=', 1)[1].split(' ')[0].rstrip().replace('"','')
            config_hash[key] = value

    f.close()

    if os.path.exists("Perimeter81.conf"):
        os.remove("Perimeter81.conf")

    conf = open("Perimeter81.conf","w+")
    conf.write("[Interface]" + '\n')
    conf.write("PrivateKey = " + config_hash['CONFIG_privateKey'] + '\n')
    conf.write("ListenPort = " + config_hash['CONFIG_port'] + '\n')
    conf.write("Address = " + config_hash['CONFIG_address'] + '\n')
    conf.write('\n')
    conf.write("[Peer]" + '\n')
    conf.write("PublicKey = " + config_hash['CONFIG_pubKey'] + '\n')
    conf.write("AllowedIPs = " + config_hash['CONFIG_allowedIP'] + '\n')
    conf.write("Endpoint = " + config_hash['CONFIG_endpoint'] + '\n')
    conf.write("PersistentKeepalive = " + '10')

    conf.close()

config_generator()

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False
if is_admin():
    enable_IP_forwarding()
    enable_IP_forwarding2()

else:
    if sys.version_info[0] == 3:
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 1)
    else:#in python2.x
        ctypes.windll.shell32.ShellExecuteW(None, u"runas", unicode(sys.executable), unicode(__file__), None, 1)

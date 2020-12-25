import ctypes, sys
import os
from os import listdir
import pathlib
import winreg as wreg


def enable_IP_forwarding():
    key = wreg.OpenKey(wreg.HKEY_LOCAL_MACHINE, r'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 0, wreg.KEY_SET_VALUE)
    wreg.SetValueEx(key, "IPEnableRouter", 1, wreg.REG_DWORD, 1)

def config_generator():
    config_hash={}

    file_list=(listdir(pathlib.Path(__file__).parent.absolute()))

    for file in file_list:
        if os.path.isfile(file):
            if 'support@perimeter81.com' in open(file).read():
                if not file.endswith('.py'):
                    config=file

    f = open(config, 'r')
    lines = f.readlines()
    #f.close()

    for line in lines:
        if line.startswith('CONFIG'):
            key = line.split('=', 1)[0]
            value = line.split('=', 1)[1].split(' ')[0].rstrip().replace('"','')
            #print(value)
            config_hash[key] = value

    f.close()

    #print(config_hash)
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


def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False
if is_admin():
    enable_IP_forwarding()
    config_generator()
else:
    if sys.version_info[0] == 3:
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 1)
    else:#in python2.x
        ctypes.windll.shell32.ShellExecuteW(None, u"runas", unicode(sys.executable), unicode(__file__), None, 1)

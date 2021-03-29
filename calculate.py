import os, sys
import hashlib
import binascii


path = ".\\test_samples"

def FileListinDirectory (Dir) :
    newFileList = []
    Dir = os.path.abspath(Dir)
    entry_list = os.listdir(Dir)

    # filtering by file extension
    # file_list_pdf = [file for file in entry_list if file.endswith(".pdf")]
    # print ("file_list_py: {}".format(file_list_pdf))

    for entry_name in entry_list:
        # print(entry_name)
        if os.path.isdir(os.path.join(Dir, entry_name)):
            newFileList.extend(FileListinDirectory(os.path.join(Dir, entry_name)))
        else:
            newFileList.append(os.path.join(Dir, entry_name))
    return newFileList

def CalculateFileHash(a):
    try:
        f = open(a, 'rb')
        raw = f.read()
        if len(raw) != 0 :
            hash_value = hashlib.sha256(raw).digest()
        f.close()
    except:
        sys.stderr.write("File open error: %s\n" % a)
        exit(1)

    return binascii.hexlify(hash_value)

files = FileListinDirectory(path)
print(len(files))

i = 0
for file in files :
    i+=1
    print (i, CalculateFileHash(file))



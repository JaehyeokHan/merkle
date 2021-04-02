import os, sys
import hashlib
import binascii
import json
import verify, reader

evidencePath = ".\\test_samples\\evidence"

def FileListinDirectory (Dir) :
    newFileList = []
    if os.path.isabs(Dir) == False:
        Dir = os.path.abspath(Dir)
    if os.path.exists(Dir) == False:
        exit(1)
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

def CalculateFileHashList(b, c):
    newHashList = []
    for a in c:
        a = os.path.join(b, 'items', a)
        if os.path.isabs(a) == False:
            a = os.path.abspath(a)
        try:
            f = open(a, 'rb')
            raw = f.read()
            if len(raw) != 0 :
                hash_value = hashlib.sha256(raw).digest()
            f.close()
        except:
            sys.stderr.write("File open error: %s\n" % a)
            exit(1)
        newHashList.append(binascii.hexlify(hash_value))

    return newHashList



itemList = reader.OpenFileListinOrder(evidencePath)
HashList = CalculateFileHashList(evidencePath, itemList)
#print(HashList)

merkleroot = verify.GetmerkleRoot(HashList)
print(merkleroot)


itemPath = os.path.join(evidencePath, 'items')


#files = FileListinDirectory(os.path.join(path, 'items'))
#print(len(files))

#
# i = 0
# for file in files:
#     i += 1
#     print (i, CalculateFileHash(file))



import os, sys
import hashlib
import binascii

class CALCULATOR:
    def __init__(self):
        self.result = 0

    def CalculateMerkleRoot(self, hashList, alg='sha256'):
        if len(hashList) == 1:
            return hashList[0]

        newHashList = []
        # Process pairs. For odd length, the last is skipped
        for i in range(0, len(hashList) - 1, 2):
            newHashList.append(self.CalculateHash2(hashList[i], hashList[i + 1], alg))
        if len(hashList) % 2 == 1:  # odd, hash last item twice
            newHashList.append(self.CalculateHash2(hashList[-1], hashList[-1], alg))

        return self.CalculateMerkleRoot(newHashList, alg)


    def CalculateHash2(self, a, b, alg='sha256'):
        concat = binascii.unhexlify(a) + binascii.unhexlify(b)
        if alg == 'md5':
            hash_value = hashlib.md5(concat).digest()
        elif alg == 'sha1':
            hash_value = hashlib.sha1(concat).digest()
        else:
            hash_value = hashlib.sha256(concat).digest()

        return binascii.hexlify(hash_value).decode('utf-8')


    def CalculateBinary(self, raw, alg='sha256'):
        if len(raw) == 0:
            return None

        else:
            if alg == 'md5':
                hash_value = hashlib.md5(raw).digest()
            elif alg == 'sha1':
                hash_value = hashlib.sha1(raw).digest()
            else:
                hash_value = hashlib.sha256(raw).digest()

        return binascii.hexlify(hash_value).decode('utf-8')


    def CalculateFile(self, targetFile, alg='sha256'):

        if os.path.isabs(targetFile) == False:
            itemPath = os.path.abspath(targetFile)

        try:
            f = open(targetFile, 'rb')
            raw = f.read()
            if len(raw) != 0:
                if alg == 'md5':
                    hash_value = hashlib.md5(raw).digest()
                elif alg == 'sha1':
                    hash_value = hashlib.sha1(raw).digest()
                else:
                    hash_value = hashlib.sha256(raw).digest()
            f.close()
        except:
            sys.stderr.write("File open error: %s (%s)\n" % targetFile, 'CalculateFile')
            exit(1)

        return binascii.hexlify(hash_value).decode('utf-8')

    def CalculateFileList(self, FileList, alg='sha256'):
        newHashList = []

        for target in FileList:
            newHashList.append(self.CalculateFile(target, alg))

        return newHashList


    def CalculateFileDict(self, FileDict, alg='sha256'):
        newHashList = []

        for idx in FileDict:
            if isinstance (FileDict[idx], list) == True:
                newHashList.append(FileDict[idx][0])

            else: # isinstance (c[idx], str) == True:

                if os.path.isabs(itemPath) == False:
                    itemPath = os.path.abspath(itemPath)

                try:
                    f = open(itemPath, 'rb')
                    raw = f.read()
                    if len(raw) != 0 :
                        hash_value = hashlib.sha256(raw).digest()
                    f.close()
                except:
                    sys.stderr.write("File open error: %s\n" % itemPath)
                    exit(1)
                newHashList.append(binascii.hexlify(hash_value).decode('utf-8'))

        return newHashList

# test
# itemDict = reader.OpenFileListinOrder(statePath)
#
# merkleroot = cal.GetmerkleRoot(HashList)


#files = FileListinDirectory(os.path.join(path, 'items'))
#print(len(files))

#
# i = 0
# for file in files:
#     i += 1
#     print (i, CalculateFileHash(file))



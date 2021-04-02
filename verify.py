import binascii
import hashlib

# Hash pairs of items recursively until a single value is obtained
def GetmerkleRoot(hashList):
    if len(hashList) == 1:
        return hashList[0]
    newHashList = []
    # Process pairs. For odd length, the last is skipped
    for i in range(0, len(hashList)-1, 2):
        newHashList.append(CalculateHash2(hashList[i], hashList[i+1]))
    if len(hashList) % 2 == 1: # odd, hash last item twice
        newHashList.append(CalculateHash2(hashList[-1], hashList[-1]))
    return GetmerkleRoot(newHashList)
 
def CalculateHash2(a, b):
    # Reverse inputs before and after hashing (SHA256)
    # due to big-endian / little-endian nonsense
    concat = binascii.unhexlify(a) + binascii.unhexlify(b)
    #print(binascii.hexlify(concat))

    hash_value = hashlib.sha256(concat).digest()
    #print(binascii.hexlify(hash_value))

    return binascii.hexlify(hash_value)

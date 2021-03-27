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
 
txHashes = [
    "bb28a1a5b3a02e7657a81c38355d56c6f05e80b9219432e3352ddcfc3cb6304c",
    "fbde5d03b027d2b9ba4cf5d4fecab9a99864df2637b25ea4cbcb1796ff6550ca",
    "8131ffb0a2c945ecaf9b9063e59558784f9c3a74741ce6ae2a18d0571dac15bb",
    "d6c7cb254aa7a5fd446e8b48c307890a2d4e426da8ad2e1191cc1d8bbe0677d7",
    "ce29e5407f5e4c9ad581c337a639f3041b24220d5aa60370d96a39335538810b",
    "45a38677e1be28bd38b51bc1a1c0280055375cdf54472e04c590a989ead82515",
    "c5abc61566dbb1c4bce5e1fda7b66bed22eb2130cea4b721690bc1488465abc9",
    "a71f74ab78b564004fffedb2357fb4059ddfc629cb29ceeb449fafbf272104ca",
    "fda204502a3345e08afd6af27377c052e77f1fefeaeb31bdd45f1e1237ca5470",
    "d3cd1ee6655097146bdae1c177eb251de92aed9045a0959edc6b91d7d8c1f158",
    "cb00f8a0573b18faa8c4f467b049f5d202bf1101d9ef2633bc611be70376a4b4",
    "05d07bb2de2bda1115409f99bf6b626d23ecb6bed810d8be263352988e4548cb"
]  	

print (GetmerkleRoot(txHashes))
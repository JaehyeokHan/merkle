import os
import reader, calculate
import json
import binascii
import hashlib

class VERIFIER:
    def __init__(self, Path):
        self.evPath = Path
        self.statePath = os.path.join(Path, 'state.json')
        self.itemsPath = os.path.join(Path, 'items')
        self.notePath = os.path.join(Path, 'note')

        if os.path.isfile(self.statePath) == False:
            print("File exist error: %s (%s)" % self.statePath, "MerkleDEM.__init__")
            exit(1)
        elif os.path.isdir(self.itemsPath) == False:
            print("Directory exist error: %s (%s)" % self.itemsPath, "MerkleDEM.__init__")
            exit(1)
        else:
            self.rd  = reader.READER(self.statePath)
            self.cal = calculate.CALCULATOR()


    def VerifyBlockhash(self):
        a = hashlib.sha256(self.rd.GetBinaryEmptyBlockHash()).digest()
        verified = binascii.hexlify(a).decode('utf-8')

        return verified


    def VerifyMerkleRoot(self):
        self.MerkleRoot = dict()

        nf = self.rd.GetValueFunction()
        mr = self.rd.GetValueMerkleRoot()

        for i in range(0, nf):
            self.MerkleRoot[self.rd.function[i]] = self.rd.merkleroot[i]

        print(self.MerkleRoot)

# main function
test = '.\\test_samples\\evidence_0'

vf = VERIFIER(test)

vf.VerifyBlockhash()

print("-------")
print("Acquired: %s" % vf.rd.GetValueBlockHash())
print("Verified: %s" % vf.VerifyBlockhash())

if vf.rd.GetValueBlockHash() != vf.VerifyBlockhash():
    print("Block hash error: NOT verified. (%s)" % "MerkleDEM.VerifyBlockhash")
    exit(1)
else:
    print("Block hash is verified.")
print("-------")

vf.VerifyMerkleRoot()
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
        print("* Blockhash")

        acquired = self.rd.GetValueBlockHash()
        verified = binascii.hexlify(hashlib.sha256(self.rd.GetBinaryEmptyBlockHash()).digest()).decode('utf-8')
        print(acquired)
        print(verified)

        if acquired != verified:
            print("Block hash error: NOT verified. (%s)" % "MerkleDEM.VerifyBlockhash")
        else:
            print(" > VALID.")

        print("")

        return verified


    def VerifyMerkleRoot(self):
        print("* Merkleroot")
        nf = self.rd.GetValueFunction()
        mr = self.rd.GetValueMerkleRoot()

        for i in range(0, nf):
            alg = self.rd.function[i]
            print(alg)
            newMerkleSourceList = []
            ms = self.rd.GetDictMerkleSource(alg)
            for j in range(0, len(ms)):
                if ms[str(j+1)][0] == 'normal':
                    inPath = os.path.join(self.itemsPath, ms[str(j + 1)][1])
                    newMerkleSourceList.append(self.cal.CalculateFile(inPath, alg))
                else:
                    newMerkleSourceList.append(ms[str(j + 1)][1])

            #print(alg, newMerkleSource)
            acquired = self.rd.merkleroot[i]
            verified = self.cal.CalculateMerkleRoot(newMerkleSourceList, alg)
            print(acquired)
            print(verified)

            if acquired != verified:
                print("Merkle hash error: NOT verified. (%s)" % "MerkleDEM.VerifyMerkleRoot")
            else:
                print(" > VALID.")

        return newMerkleSourceList


# main function
evidence_0 = '.\\test_samples\\evidence_0' # logically imaged items. (total : 4)
evidence_1 = '.\\test_samples\\evidence_0' # item 2,3 is operated. (encrypted, deleted)

e0 = VERIFIER(evidence_0)
e0.VerifyBlockhash()
e0.VerifyMerkleRoot()
print("\n--------------------\n")
e1 = VERIFIER(evidence_1)
e1.VerifyBlockhash()
e1.VerifyMerkleRoot()
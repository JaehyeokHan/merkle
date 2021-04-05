import sys, os
import json
import calculate

class READER:
    def __init__(self, Filepath):
        self.statePath = Filepath
        if os.path.isabs(Filepath) == False:
            self.statePath = os.path.abspath(Filepath)

        try:
            with open (self.statePath, 'r') as f:
                json_data = json.load(f)
        except:
            sys.stderr.write("File open error: %s (%s)\n" % Filepath, 'REDAER.__init__')
            exit(1)
        self.json_data = json_data

    def PrintJsonData(self):
        return json.dumps(self.json_data, indent=4)

    def GetValueBlockHash(self):
        self.BlockHash = self.json_data['hash']
        return self.BlockHash

    def GetValueFunction(self):
        self.function = self.json_data['function']
        return len(self.function)

    def GetValuenItem(self):
        self.nItem = self.json_data['nItem']
        return self.nItem

    def GetValueMerkleRoot(self):
        self.merkleroot = self.json_data['merkleroot']
        return len(self.merkleroot)

    def GetBinaryEmptyBlockHash(self):
        with open(self.statePath, 'rb') as f:
            raw = f.read(16)
            f.seek(64, 1)
            raw += f.read()

        return raw

    def GetDictMerkleSource(self):
        newItemDict = dict()

        nf = self.GetValueFunction() # the number of functions
        ni = self.GetValuenItem()
        items_data = self.json_data['items']

        for i in range(0, ni):
            items_attribute = items_data[str(i + 1)]['attribute']
            if items_attribute == 'normal':
                items_name = items_data[str(i + 1)]['name']
                newItemDict[str(i + 1)] = (items_attribute, items_name)
            else:
                print(items_data[str(i + 1)]['hash'])
                newItemDict[str(i + 1)] = (items_attribute, items_data[str(i + 1)]['hash'])

        return newItemDict


def WriteBinaryBlock(json_data, outPath):
    json_data["hash"] = ""

    blockhash = str(calculate.CalculateBinary(json_data))
    json_data["hash"] = blockhash

    with open(outPath, 'w') as outfile:
        json.dump(json_data, outfile, indent=4)

    return blockhash


# Recursive file scan in the directory
def FileListinDirectory(Dir) :
    newFileList = []
    if os.path.isabs(Dir) == False:
        Dir = os.path.abspath(Dir)

    if os.path.exists(Dir) == False:
        print("File open error: %s (%s)\n" % Dir, 'FileListinDirectory')
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
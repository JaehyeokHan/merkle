import sys, os
import json

path = 'C:\\Users\\Jack\\Documents\\GitHub\\merkle\\test_samples\\evidence\\state.json'

def OpenJsonFiledata(a):
    try:
        with open (a, 'r') as f:
            json_data = json.load(f)
    except:
        sys.stderr.write("File open error: %s\n" % a)
        exit(1)

    return json.dumps(json_data, indent=3)


def OpenFileListinOrder(a):
    newItemList = []
    statePath = os.path.join(a, 'state.json')
    try:
        with open (statePath, 'r') as f:
            json_data = json.load(f)
    except:
        sys.stderr.write("File open error: %s\n" % statePath)
        exit(1)

    count_data = json_data['count']
    items_data = json_data['items']

    for i in range(0, count_data):
        items_name = json_data['items'][str(i+1)]['name']
        newItemList.append(items_name)

    return newItemList

#print(OpenJsonFiledata(path))

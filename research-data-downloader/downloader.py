import requests
from requests_cloudkit import CloudKitAuth
from restmapper import RestMapper
import json
from StringIO import StringIO
import urllib

IMAGES = True # download images as PNG files.

def save_record_touches(record):
    """
    Saves the touches field of a record a text file with the record's name.
    """
    name = record['recordName']
    touches = record['fields']['Touches']['value']
    date = record['fields']['Date']['value']
    image_url = record['fields']['Image']['value']['downloadURL']
    #touch_io = StringIO(touches)
    #df = pd.read_csv(touch_io)
    text_file = open(name + ".csv", "w")
    text_file.write(touches)
    text_file.close()
    if IMAGES:
        urllib.urlretrieve(image_url,name+".png")
    print(name)

def main():
    """
    Downloads all data from the MicroJam CloudKit database and saves touch records as text files.
    """
    print("Going to download data from CloudKit")
    auth = CloudKitAuth(key_id="da1eaedabe00e50036abcce7fb4deafc8e4cca4d4e53c1b5339519a3f95b27c6", key_file_name="/Users/charles/src/microjam/research-data-downloader/eckey.pem")
    CloudKit = RestMapper("https://api.apple-cloudkit.com/database/1/iCloud.au.com.charlesmartin.microjam/development/")
    cloudkit = CloudKit(auth=auth)
    query = {'recordType':'Performance'}
    data = {
        "zoneID": {'zoneName': '_defaultZone'},
        "resultsLimit": "10000",
        "query": query,
        "zoneWide": "true",
    }
    response = cloudkit.POST.public.records.query(json.dumps(data))
    print("Data Downloaded. Now saving touch records.")
    for rec in response['records']:
        save_record_touches(rec)
    print("Done saving records.")

if __name__ == "__main__":
    main()

# Records look like:
# [u'recordType',
#  u'created',
#  u'recordName',
#  u'fields',
#  u'modified',
#  u'zoneID',
#  u'recordChangeTag']

# Fields looks like:
# [u'PerformedAt',
#  u'Touches',
#  u'Performer',
#  u'ReplyTo',
#  u'Image',
#  u'Instrument',
#  u'Date',
#  u'Colour']

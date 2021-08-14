#!/usr/bin/python3

import sys
import xml.etree.ElementTree as ET
import psycopg2

numArgs = len(sys.argv)

if  numArgs != 2:
  print("Import file not specified.")
  exit()

nextNodeId = 0
nextWayId = 0;
nextRelsId = 0;

con = psycopg2.connect(database="gis", user="renderer", password="renderer", host="localhost", port="5432")
cur = con.cursor()
cur.execute("select max(id) from planet_osm_nodes;")
rows = cur.fetchall()

nextNodeId = int(rows[0][0]) + 1

cur.execute("select max(id) from planet_osm_ways;")
rows = cur.fetchall()
nextWayId = int(rows[0][0]) + 1


cur.execute("select max(id) from planet_osm_rels;")
rows = cur.fetchall()
nextRelsId = int(rows[0][0]) + 1

con.close()

if nextNodeId < 99000000000:
  nextNodeId = 99000000000

if nextWayId < 9000000000:
  nextWayId = 9000000000

if nextRelsId < 900000000:
  nextRelsId = 900000000

print("nodes=", nextNodeId)
print("ways=", nextWayId)
print("rels=", nextRelsId)

osmDoc = ET.parse(sys.argv[1])

nodesToProcess = []

for node in osmDoc.findall(".//node"):
  nodeId = int(node.attrib.get('id'))
  if nodeId < 0:
    nodesToProcess.append(nodeId)

print("%s nodes to process" % len(nodesToProcess))

for nodeToProcess in nodesToProcess:
  print("Processing node " + str(nodeToProcess) + " to " + str(nextNodeId))

  path = ".//node[@id='" + str(nodeToProcess) + "']"
  for node in osmDoc.findall(path):
    node.set('id', str(nextNodeId))
    #print("N    %s" % node)

  path = ".//way/nd[@ref='" + str(nodeToProcess) + "']"
  for way in osmDoc.findall(path):
    way.set('ref', str(nextNodeId))
    #print("W    %s" % way)

  path = ".//relation/member[@type='node'][@ref='" + str(nodeToProcess) + "']"
  for rel in osmDoc.findall(path):
    rel.set('ref', str(nextNodeId))
    #print("R    %s" % rel)

  nextNodeId = nextNodeId + 1

waysToProcess = []

for way in osmDoc.findall(".//way"):
  wayId = int(way.attrib.get('id'))
  if wayId < 0:
    waysToProcess.append(wayId)

print("%s ways to process" % len(waysToProcess))

for wayToProcess in waysToProcess:
  print("Processing way " + str(wayToProcess) + " to " + str(nextWayId))


  path = ".//way[@id='" + str(wayToProcess) + "']"
  for way in osmDoc.findall(path):
    way.set('id', str(nextWayId))
    #print("W    %s" % way)

  path = ".//relation/member[@type='way'][@ref='" + str(wayToProcess) + "']"
  for rel in osmDoc.findall(path):
    rel.set('ref', str(nextWayId))
    #print("R    %s" % rel)

  nextWayId = nextWayId + 1

relsToProcess = []

for rel in osmDoc.findall(".//relation"):
  relId = int(rel.attrib.get('id'))
  if relId < 0:
    relsToProcess.append(relId)

print("%s rels to process" % len(relsToProcess))

for relToProcess in relsToProcess:
  print("Processing rel " + str(relToProcess) + " to " + str(nextRelsId))

  path = ".//relation[@id='" + str(wayToProcess) + "']"
  for rel in osmDoc.findall(path):
    rel.set('id', str(nextRelsId))
    #print("R    %s" % rel)

  nextRelsId = nextRelsId + 1


def sorter(elem):
  if elem.tag == 'node':
    return int(elem.get('id', 0))
  elif elem.tag == 'way':
    return int(elem.get('id', 0)) + 2000000000000
  elif elem.tag == 'relation':
    return int(elem.get('id', 0)) + 3000000000000
  else:
    return 0

def sortchildrenby(parent):
    parent[:] = sorted(parent, key=lambda child: sorter(child))

sortchildrenby(osmDoc.getroot())
osmDoc.write(sys.argv[1] + ".new")

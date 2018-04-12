#!/usr/bin/env python3

import os, sys
from lxml.etree import Element, ElementTree


class XmlBase (object):
    nsmap = {
        'ds': 'http://schema.programmfabrik.de/database-schema/0.1',
        'es': 'http://schema.programmfabrik.de/easydb-database-schema/0.1',
        'em': 'http://schema.programmfabrik.de/easydb-mask-schema/0.1',
    }

class Searchable (XmlBase):
    def __init__(self, xml):
        self.search_expert = xml.find('em:search/em:expert', self.nsmap).attrib['enabled'] == '1'
        self.search_facet = xml.find('em:search/em:facet', self.nsmap).attrib['enabled'] == '1'
        self.search_fulltext = xml.find('em:search/em:fulltext', self.nsmap).attrib['enabled'] == '1'
        self.search_flags = \
            (self.search_expert and 'E' or '') + \
            (self.search_facet and 'F' or '') + \
            (self.search_fulltext and 'V' or '')


class Field (Searchable):
    def __init__(self, xml): 
        super(Field, self).__init__(xml)
        self.name = xml.attrib.get('column-name-hint')

class LinkedTable (Searchable):
    def __init__(self, xml):
        super(LinkedTable, self).__init__(xml)
        self.name = xml.attrib.get('other-table-hint')

class ReverseLinkedTable (LinkedTable):
    def __init__(self, xml):
        super(ReverseLinkedTable, self).__init__(xml)

class Analyzer (XmlBase):
    @classmethod
    def analyze_masks(cls, maskxmlfile, mask_name):
        tree = ElementTree()
        tree.parse(maskxmlfile)
        root = tree.getroot()

        if mask_name is not None:
            mask = root.find("em:mask[@name='{0}']".format(mask_name), cls.nsmap)
            if mask is None:
                sys.stderr.write("failed to find mask '{0}'\n".format(mask_name))
                sys.exit(1)
            cls._analyze_mask(mask)
        else:
            for mask in root.findall('em:mask', cls.nsmap):
                cls._analyze_mask(mask)

    @classmethod
    def _analyze_mask(cls, mask, indent = ''):
        print("{0}M:{1}".format(indent, mask.get('name', '<unnamed>')))
        for rlinkedxml in mask.findall('em:fields/em:reverse-linked-table', cls.nsmap):
            rlinked = ReverseLinkedTable(rlinkedxml)
            if len(rlinked.search_flags):
                print("{0}  R:{1} ({2})".format(indent, rlinked.name, rlinked.search_flags))
                maskxml = rlinkedxml.find('em:mask', cls.nsmap)
                if maskxml is not None:
                    cls._analyze_mask(maskxml, indent + '    ')
        for linkedxml in mask.findall('em:fields/em:linked-table', cls.nsmap):
            linked = LinkedTable(linkedxml)
            if len(linked.search_flags):
                print("{0}  N:{1} ({2})".format(indent, linked.name, linked.search_flags))
                maskxml = linkedxml.find('em:mask', cls.nsmap)
                if maskxml is not None:
                    cls._analyze_mask(maskxml, indent + '    ')
        for fieldxml in mask.findall('em:fields/em:field', cls.nsmap):
            field = Field(fieldxml)
            if len(field.search_flags):
                print("{0}  F:{1} ({2})".format(indent, field.name, field.search_flags))
    

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.stderr.write('usage: {0} <maskset.xml> [<mask name>]\n'.format(sys.argv[0]))
        sys.exit(1)
    if not os.path.isfile(sys.argv[1]):
        sys.stderr.write('failed to find {0}\n'.format(sys.argv[1]))
        sys.exit(1)
    Analyzer.analyze_masks(sys.argv[1], len(sys.argv) > 2 and sys.argv[2] or None)

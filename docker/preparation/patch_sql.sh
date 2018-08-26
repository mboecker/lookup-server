#!/bin/bash
fn="ExpDB_SNAPSHOT.sql.gz"
mv $fn $fn.bk
pv $fn.bk | gzip -d | sed --expression="s/ENGINE/& ROW_FORMAT=DYNAMIC/" | gzip > $fn
rm $fn.bk

#pv $fn.fullbk | gzip -d | sed --expression="s/ENGINE/& ROW_FORMAT=DYNAMIC/" | gzip > $fn

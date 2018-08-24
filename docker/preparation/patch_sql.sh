#!/bin/bash
fn="ExpDB_SNAPSHOT.sql.gz"
mv $fn $fn.bk
zcat $fn.bk | sed --expression="s/ENGINE/& ROW_FORMAT=DYNAMIC/" | gzip > $fn
rm $fn.bk

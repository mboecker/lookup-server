#!/bin/bash
while ! mysqladmin ping --silent; do
    sleep 1
done

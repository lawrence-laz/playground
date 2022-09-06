#!/bin/bash

dotnet build native.csproj

echo "Built a standalone dotnet executable, which doesn't require dotnet runime"
echo "Size of file:"

numfmt --to=iec-i --suffix=B --format="%.3f" `wc -c native | cut -d " " -f1`

echo "Running app..."

./native


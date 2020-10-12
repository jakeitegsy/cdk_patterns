# automatically run the $FILENAME on save
FILENAME=
while true; do
	find . -name "*.sh" | entr -d ./$FILENAME.sh;
done

include_markers=

./obj.marker: debug/obj/ $(include_markers)
	touch ./obj.marker

/obj.o: /.marker ./obj.marker

objects=/obj.o

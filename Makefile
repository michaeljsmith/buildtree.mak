#TODO: Handle includes outside of tree.
dependency_extension=dep.mak

marker_extension=marker
dirmarker_extension=dirmarker

config=debug
config_prefix=$(config)

module_name=testmod
module_source_dir=.
module_dep_dir=dep
module_dep_path=$(config_prefix)/$(module_dep_dir)
module_obj_dir=obj
module_obj_path=$(config_prefix)/$(module_obj_dir)
module_bin_dir=bin
module_bin_path=$(config_prefix)/$(module_bin_dir)

module_target=$(module_bin_path)/$(module_name)

source_dependency_file=$(module_dep_path)/.$(dependency_extension)

.PHONY: default clean
default: $(module_target) $(config_prefix)/.$(dirmarker_extension)

clean:
	rm -rf $(config_prefix)

-include $(source_dependency_file)

$(module_target): $(objects) |$(module_bin_path)/.$(dirmarker_extension)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

%/.$(dirmarker_extension):
	@mkdir -p $(@D)
	@touch $@

.PRECIOUS: %/.$(dirmarker_extension)

%.$(marker_extension):
	@touch $@

.PRECIOUS: %.$(marker_extension)

$(module_obj_path)/%.cpp.o: $(module_source_dir)/%.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $(module_obj_path)/$*.cpp.o $(module_source_dir)/$*.cpp

$(module_dep_path)/%$(dependency_extension): $(module_source_dir)/% $(module_dep_path)/%$(dirmarker_extension)
	$(output_directory_fragment)

$(module_dep_path)/%.cpp.$(dependency_extension): $(module_source_dir)/%.cpp
	$(output_include_dependencies)
	$(append_object_prerequisites)

$(module_dep_path)/%.h.$(dependency_extension): $(module_source_dir)/%.h
	$(output_include_dependencies)

define output_directory_fragment
@output_path=$@; \
directory=$(module_source_dir)/$*; \
object_directory=$(module_obj_path)/$*; \
directory_marker_path=$$directory/.$(dirmarker_extension); \
echo "" > $$output_path; \
if [ -f $$directory_marker_path ]; then \
	exit 0; \
fi; \
dependency_directory=$$(dirname $$output_path); \
entries=$$(ls -p $$directory); \
echo "directory=$$directory" >> $$output_path; \
echo "dependency_directory=$$dependency_directory" >> $$output_path; \
echo "object_directory=$$object_directory" >> $$output_path; \
echo "" >> $$output_path; \
echo "old_total_objects=\$$(total_objects)" >> $$output_path; \
echo "total_objects=" >> $$output_path; \
for entry in $$entries; do \
	echo "" >> $$output_path; \
	echo "objects=" >> $$output_path; \
	echo "-include $$dependency_directory/$$entry.$(dependency_extension)" >> $$output_path; \
	echo "total_objects:=\$$(total_objects) \$$(objects)" >> $$output_path; \
done; \
echo "" >> $$output_path; \
echo "objects:=\$$(total_objects)" >> $$output_path; \
echo "total_objects:=\$$(old_total_objects)" >> $$output_path
endef

define output_include_dependencies
@source_path="$<"; \
output_path="$@"; \
object_directory="$(module_obj_path)/$(*D)"; \
source_file=$$(basename $$source_path); \
source_directory=$$(dirname $$source_path); \
output_directory=$$(dirname $$output_path); \
marker_file=$$output_directory/$$source_file.$(marker_extension); \
include_dirs="$$(echo -e "$$source_directory\n$$include_dirs")"; \
include_files=$$(sed -n -e 's/^\s*#include\s\+"\(.*\)".*$$/\1/p' $$source_path); \
OLDIFS=$$IFS; \
IFS=$$(echo -en "\n\b"); \
include_paths=""; \
for include_file in $$include_files; do \
	include_path=""; \
	for include_dir in $$include_dirs; do \
		path="$$include_dir/$$include_file"; \
		if [ -f $$path ]; then \
			include_path=$${path#./}; \
		fi; \
	done; \
	if [ -z $$include_path ]; then \
		echo "Cannot find include file \"$$include_file\", referenced in \"$$source_path\"." >&2; \
	else \
		abspath=$$(readlink -f $$include_path); \
		curpath=$$(readlink -f $$(pwd)); \
		relpath=$$(echo $$abspath | sed -e "s*^$$curpath/**"); \
		include_paths=$$(echo -e "$$include_paths\n$$relpath"); \
	fi; \
done; \
IFS=$$OLDIFS; \
echo "" > "$$output_path"; \
echo -n "include_markers=" >> "$$output_path"; \
OLDIFS=$$IFS; \
IFS=$$(echo -en "\n\b"); \
for include_path in $$include_paths; do \
	echo -ne " \\\\\n    \$$(module_dep_path)/$$include_path.marker" >> "$$output_path"; \
done; \
echo "" >> "$$output_path"; \
echo "" >> "$$output_path"; \
IFS=$$OLDIFS; \
echo "$$marker_file: $${source_path#./} \$$(include_markers)" >> "$$output_path"; \
echo "" >> "$$output_path"
endef

define append_object_prerequisites
@output_path="$@"; \
source_path=$(module_source_dir)/$*.cpp; \
object_directory=$(module_obj_path)/$(*D); \
object_directory=$${object_directory%/.}; \
source_file=$$(basename $$source_path); \
source_directory=$$(dirname $$source_path); \
output_directory=$$(dirname $$output_path); \
object_path=$$object_directory/$$source_file.o; \
marker_file=$$output_directory/$$source_file.$(marker_extension); \
object_dir_marker=$$object_directory/.$(dirmarker_extension); \
echo "$$object_path: $$object_dir_marker $$marker_file" >> $$output_path; \
echo "" >> $$output_path; \
echo "objects=$$object_path" >> $$output_path
endef


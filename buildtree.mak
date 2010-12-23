##############################################################################
# 
# buildtree.mak
#
# Revision history:
#
# * 2010/12/04 Michael Smith <msmith@msmith.id.au>: Initial release (1.0).
#
#
# The contents of this file are hereby placed into the public domain. This
# file comes with ABSOLUTELY NO WARRANTY.
#
#
# This is an implementation of a simple build system in GNU make. It has been
# tested using GNU make 3.81 on Arch Linux, but should run on any system that
# includes make, bash and standard utilities such as sed.
#
# Features include:
#
# * All generated and object files are built into a separate directory tree,
# allowing multiple configurations to be switched between seamlessly.
#
# * Dependencies are tracked automatically, and using minimal rebuilding -
# make updates dependencies using prerequisite rules (unlike cc -M which
# involves excessive updating).
#
# * No recursive make invocations.
#
# * Little overhead in determining required work when few files need
# rebuilding, even on large projects.
#
# * No need to add source files to makefile manually.
#
#
# TODO: Handle includes outside of tree.
##############################################################################

# Basic configuration variables.
config=debug
module_name=testmod
module_source_dir=.
module_dep_dir=dep
module_obj_dir=obj
module_bin_dir=bin

# Internal defines. Configure these per preferences.
module_target=$(module_bin_path)/$(module_name)

dependency_extension=dep.mak

marker_extension=marker
dirmarker_extension=dirmarker

config_prefix=$(config)
module_dep_path=$(config_prefix)/$(module_dep_dir)
module_obj_path=$(config_prefix)/$(module_obj_dir)
module_bin_path=$(config_prefix)/$(module_bin_dir)

source_dependency_file=$(module_dep_path)/.$(dependency_extension)

# Main targets. Add others here to taste.
.PHONY: default clean
default: $(module_target) $(config_prefix)/.$(dirmarker_extension)

clean:
	rm -rf $(config_prefix)

# Include the root dependency file - this will recursively build and include
# makefile fragments describing the dependencies of all files in the tree.
# This relies on the feature of GNU make where include statements first look
# for rules to update included makefile and update them before including them.
objects:=
-include $(source_dependency_file)

# Rule for linking module. Change this if target is SO/DLL, for instance.
$(module_target): $(objects) |$(module_bin_path)/.$(dirmarker_extension)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

# Rules for building c and cpp files - dependencies are handled later.
# If adding other file types add an appropriate dependency generation rule
# below (eg c would be trivial to add).
$(module_obj_path)/%.cpp.o: $(module_source_dir)/%.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $(module_obj_path)/$*.cpp.o $(module_source_dir)/$*.cpp

$(module_obj_path)/%.c.o: $(module_source_dir)/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $(module_obj_path)/$*.c.o $(module_source_dir)/$*.c


##############################################################################
# Remainder of makefile is for dependency generation and object tree creation.
##############################################################################

# Rule for creating directories - marker files are included as dependencies
# whenever a target requires a directory to exist.
%/.$(dirmarker_extension):
	@mkdir -p $(@D)
	@touch $@
.PRECIOUS: %/.$(dirmarker_extension)

# Other marker files are used to incorporate dependencies of header files
# recursively as dependencies of including files.
%.$(marker_extension):
	@touch $@
.PRECIOUS: %.$(marker_extension)

$(module_dep_path)/%$(dependency_extension): $(module_source_dir)/% $(module_dep_path)/%$(dirmarker_extension)
	$(output_directory_fragment)

# Rules for generating a makefile fragment describing dependencies of c/c++
# source files. Will cause the associated object file to be registered in the
# $(objects) variable, so that module can use it as a prerequisite.
$(module_dep_path)/%.c.$(dependency_extension): $(module_source_dir)/%.c
	$(output_include_dependencies)
	$(append_object_prerequisites)

$(module_dep_path)/%.cpp.$(dependency_extension): $(module_source_dir)/%.cpp
	$(output_include_dependencies)
	$(append_object_prerequisites)

# Rules for generating a makefile fragment describing dependencies of c/c++
# source files.
$(module_dep_path)/%.h.$(dependency_extension): $(module_source_dir)/%.h
	$(output_include_dependencies)

##############################################################################
# Bash code for generating dependencies extracted and listed below, for
# neatness sake.
##############################################################################

# Generate dependency makefile fragment for a directory.
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
entries=$$(ls -p $$directory | grep "^[A-Za-z]"); \
for entry in $$entries; do \
	echo "-include $$dependency_directory/$$entry.$(dependency_extension)" >> $$output_path; \
done; \
echo "" >> $$output_path;
endef

# Generate dependency makefile fragment for an include file.
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

# Append object declaration for a source file - assumes that include
# dependencies have already been written to file.
define append_object_prerequisites
@output_path="$@"; \
source_path="$<"; \
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
echo "objects+=$$object_path" >> $$output_path
endef


dependency_extension=dep.mak

marker_extension=marker

config=debug
config_prefix=$(config)

module_name=testmod
module_source_dir=.
module_dep_dir=dep
module_dep_path=$(config_prefix)/$(module_dep_dir)

module_target=$(module_name)

source_dependency_file=$(module_dep_path)/src.$(dependency_extension)

.PHONY: default
default: $(module_target)

include $(source_dependency_file)

$(module_target): $(objects)
	echo "DEPENDENCIES=$^"

%/.$(marker_extension):
	mkdir -p $(@D)
	touch $@

#%.h.$(marker_extension):
#	echo "Compiling header."
#	touch $@

.PRECIOUS: %.$(marker_extension)

$(source_dependency_file): $(module_dep_path)/.$(marker_extension)
	bash makelib/generate_directory_dependencies $@ $(module_source_dir)

.PHONY: clean devcontainer-up devcontainer-exec test impl

#impl:
#	cd impl && $(MAKE) all

#test:
#	cd tb && $(MAKE) all

devcontainer-up:
	devcontainer up --workspace-folder $(ROOT_DIR)

devcontainer-exec:
	devcontainer exec --workspace-folder $(ROOT_DIR) bash

clean:
	rm -f mcu_soc.f
	rm -rf obj_dir/
	rm -f dump.fst
	rm -f dump_debug.fst

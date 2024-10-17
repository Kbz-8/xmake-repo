-- Compile shaders to includables headers
rule("compile.shaders")
	set_extensions(".nzsl", ".nzslb")
	add_deps("@nzsl/find_nzsl")

	on_config(function (target)
		local archives = {}

		for _, sourcebatch in pairs(target:sourcebatches()) do
			local rulename = sourcebatch.rulename
			if rulename == "@nzsl/compile.shaders" then
				for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
					local fileconfig = target:fileconfig(sourcefile)
					if fileconfig and fileconfig.archive then
						local archivefiles = archives[fileconfig.archive]
						if not archivefiles then
							archivefiles = {}
							archives[fileconfig.archive] = archivefiles
						end
						table.insert(archivefiles, path.join(path.directory(sourcefile), path.basename(sourcefile) .. ".nzslb"))
					end
				end
			end
		end

		target:rule_add(target:rule("@nzsl/archive.shaders"))
		for archive, archivefiles in table.orderpairs(archives) do
			local args = { rule = "@nzsl/archive.shaders", always_added = true, compress = true, files = archivefiles }
			if archive:endswith(".nzsla.h") or archive:endswith(".nzsla.hpp") then
				args.header = true
			end

			target:add("files", archive, args)
		end
	end)

	before_buildcmd_file(function (target, batchcmds, shaderfile, opt)
		local outputdir = target:data("nzsl_includedirs")
		local nzslc = target:data("nzslc")
		local runenvs = target:data("nzsl_runenv")
		assert(nzslc, "nzslc not found! please install nzsl package with nzslc enabled")

		local fileconfig = target:fileconfig(shaderfile) or {}
		local header = fileconfig.archive == nil

		-- add commands
		batchcmds:show_progress(opt.progress, "${color.build.object}compiling.shader %s", shaderfile)
		local argv = { "--compile=nzslb" .. (header and "-header" or ""), "--partial", "--optimize" }
		if outputdir then
			batchcmds:mkdir(outputdir)
			table.insert(argv, "--output=" .. outputdir)
		end

		-- handle --log-format
		local kind = target:data("plugin.project.kind") or ""
		if kind:match("vs") then
			table.insert(argv, "--log-format=vs")
		end

		table.insert(argv, shaderfile)

		batchcmds:vrunv(nzslc.program, argv, { curdir = ".", envs = runenvs })

		local outputfile = path.join(outputdir or path.directory(shaderfile), path.basename(shaderfile) .. ".nzslb" .. (header and ".h" or ""))

		-- add deps
		batchcmds:add_depfiles(shaderfile)
		batchcmds:add_depvalues(nzslc.version)
		batchcmds:set_depmtime(os.mtime(outputfile))
		batchcmds:set_depcache(target:dependfile(outputfile))
	end)

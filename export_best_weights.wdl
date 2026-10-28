version 1.0

workflow export_best_weights {
    input {
        Array[String] output_weight_file_names
        Array[File] weight_files
    }

    call copy_files {
        input:
            files = weight_files,
            filenames = output_weight_file_names
    }

    # output {
    #     Array[File] copied_files = copy_files.copied_files
    # }
}


task copy_files {
    input {
        Array[File] files
        Array[String] filenames
    }

    command <<<
        for i in $(seq 0 $((${#files[@]} - 1))); do
            #cp "${files[$i]}" "${filenames[$i]}"
            echo "${files[$i]} -> ${filenames[$i]}"
        done
    >>>

    # output {
    #     Array[File] copied_files = filenames
    # }

    runtime {
        docker: "uwgac/anvildatamodels:0.8.1"
        memory: "32 GB"
        disks: "local-disk 100 SSD"
    }
}

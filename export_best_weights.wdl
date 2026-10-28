version 1.0

workflow export_best_weights {
    input {
        Array[String] output_weight_file_names
        Array[File] weight_files
    }

    call tar_files {
        input:
            files = weight_files,
            filenames = output_weight_file_names
    }

    output {
        File tar_file = tar_files.tar_file
    }
}


task tar_files {
    input {
        Array[File] files
        Array[String] filenames
    }

    command <<<
        file_array=(~{sep=' ' files})
        filename_array=(~{sep=' ' filenames})

        mkdir weight_files
        for index in ${!file_array[*]}; do
            echo "${file_array[$index]} -> ${filename_array[$index]}.tsv"
            cp "${file_array[$index]}" "weight_files/${filename_array[$index]}.tsv"
        done

        tar --create --file=weight_files.tar weight_files

        tar --list --file=weight_files.tar
    >>>

    output {
        File tar_file = "weight_files.tar"
    }

    runtime {
        docker: "uwgac/anvildatamodels:0.8.1"
        memory: "32 GB"
        disks: "local-disk 100 SSD"
    }
}

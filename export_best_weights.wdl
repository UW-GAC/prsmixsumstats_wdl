version 1.0

workflow export_best_weights {
    input {
        Array[String] output_weight_file_prefixes
        Array[File] weight_files
        String out_tar_file_prefix
    }

    call tar_files {
        input:
            files = weight_files,
            file_prefixes = output_weight_file_prefixes
    }

    output {
        File tar_file = tar_files.tar_file
    }
}


task tar_files {
    input {
        Array[File] files
        Array[String] file_prefixes
        String out_tar_file_prefix
    }

    command <<<
        file_array=(~{sep=' ' files})
        file_prefix_array=(~{sep=' ' file_prefixes})

        echo $file_array
        echo $file_prefix_array

        mkdir ~{out_tar_file_prefix}
        for index in ${!file_array[*]}; do
            echo "${file_array[$index]} -> ${file_prefix_array[$index]}.tsv"
            cp "${file_array[$index]}" "~{out_tar_file_prefix}/${file_prefix_array[$index]}.tsv"
        done

        tar --create --file=~{out_tar_file_prefix}.tar ~{out_tar_file_prefix}

        tar --list --file=~{out_tar_file_prefix}.tar
    >>>

    output {
        File tar_file = "~{out_tar_file_prefix}.tar"
    }

    runtime {
        docker: "uwgac/anvildatamodels:0.8.1"
        memory: "32 GB"
        disks: "local-disk 100 SSD"
    }
}

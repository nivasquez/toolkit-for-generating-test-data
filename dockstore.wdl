version 1.0

task downSamplingSAMBAM {
  input {
  	File inputFile
  	String inputFileName
  	Float disk_size
  }

  command {
    # Downsampling and Subsetting data by samtools	
    samtools view -bs 35.1 ${inputFile} > downsampled.${inputFileName}
  }

  output {
    File downsampledInputFile = "downsampled.${inputFileName}"
  }

 runtime {
    docker: "quay.io/ibrahimjabarkhel/toolkit-for-generating-test-data:latest"
    cpu: 1
    memory: "10 GB"
    disks: "local-disk " + disk_size + " HDD"
  }
}
task downSamplingCRAM {
  input {
  	File inputFile
  	File referenceFile
  	String inputCramFileName
  	Float disk_size
  }

  command {
    # Downsampling and Subsetting data by Samtools	
    samtools view -b ${inputFile} -T ${referenceFile} > ${inputCramFileName}.bam
    samtools view -bs 35.1 ${inputCramFileName}.bam > downsampled.${inputCramFileName}.bam
    samtools view -C downsampled.${inputCramFileName}.bam -T ${referenceFile} -o downsampled.${inputCramFileName}.cram
  }

  output {
    File downsampledCramFile = "downsampled.${inputCramFileName}.cram"
  }

 runtime {
    docker: "quay.io/ibrahimjabarkhel/toolkit-for-generating-test-data:latest"
    cpu: 1
    memory: "10 GB"
    disks: "local-disk " + disk_size + " HDD"
  }
}


workflow downsampling_File {
  input {
        Boolean isCram
        File referenceFile
  	File inputFile
  	# Optional input to increase all disk sizes in case of outlier sample with strange size behavior
  	Int? increase_disk_size

  }

  # Some tasks need wiggle room, and we also need to add a small amount of disk to prevent getting a
  # Cromwell error from asking for 0 disk when the input is less than 1GB
  Int additional_disk = select_first([increase_disk_size, 20])

  # Get the size of the standard reference file
  Float bam_size = size(inputFile, "GB")

  String inputFileName = basename("${inputFile}")
  if (!isCram) {
     call downSamplingSAMBAM { input: inputFile = inputFile,
                    inputFileName = inputFileName,
                    disk_size = bam_size + additional_disk
     }
  }

  String inputCramFileName = basename("${inputFile}", ".cram")
  if (isCram) {
     call downSamplingCRAM { input: inputFile = inputFile,
                    inputCramFileName = inputCramFileName,
                    referenceFile = referenceFile,
                    disk_size = bam_size + additional_disk
     }
  }
  
}
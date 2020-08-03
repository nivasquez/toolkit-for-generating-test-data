version 1.0

task downSamplingCRAM {
  input {
  	File inputFile
  	File referenceFile
  	String inputFileName
  	Float disk_size
  }

  command {
    # Downsampling and Subsetting data by Samtools
    if [ -f ${referenceFile} ]
    then
	# converting cram to bam
        samtools view -b ${inputFile} -T ${referenceFile} > ${inputFileName}.bam
	# downsampling and subsetting the file
        samtools view -bs 35.1 ${inputFileName}.bam > downsampled.${inputFileName}.bam
	# converting back to cram file
        samtools view -C downsampled.${inputFileName}.bam -T ${referenceFile} -o downsampled.${inputFileName}
    else
	#downsampling and subsetting the file
        samtools view -bs 35.1 ${inputFile} > downsampled.${inputFileName}
    fi
  }

  output {
    File downsampledFile = "downsampled.${inputFileName}"
  }

 runtime {
    docker: "quay.io/ibrahimjabarkhel/toolkit-for-generating-test-data:latest"
    memory: "15 GB"
    disks: "local-disk " + disk_size + " HDD"
  }
}


workflow downsampling_File {
  input {
        File referenceFile
  	File inputFile
  	# Optional input to increase all disk sizes in case of outlier sample with strange size behavior
	# declare input variable that will help in increase disk size if needed
  	Int? increase_disk_size

  }

  # Increase the disk size if the remaining disk size is less than 1 GB
  Int additional_diskSize = select_first([increase_disk_size, 20])

  # Get the size of the standard input file
  Float inputFileSize = size(inputFile, "GB")


  String inputFileName = basename("${inputFile}")

  call downSamplingCRAM { input: inputFile = inputFile,
                 inputFileName = inputFileName,
                 referenceFile = referenceFile,
                 disk_size = inputFileSize + additional_diskSize
  }
}
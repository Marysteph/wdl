task scatter_task {
  Int count
  File in

  command <<<
    egrep ^.{${count}}$ ${in} || exit 0
  >>>
  output {
    Array[String] words = tsv(stdout())
  }
}

task gather_task {
  Int count
  Array[Array[String]] word_lists

  command {
    python3 <<CODE
    import json
    with open('count', 'w') as fp:
      fp.write(str(int(${count}) - 1))
    with open('wc', 'w') as fp:
      fp.write(str(sum([len(x) for x in json.loads(open("${word_lists}").read())])))
    CODE
  }
  output {
    Int count = read_int("count")
  }
}

workflow wf {
  Array[File] files
  Int count

  scatter(filename in files) {
    call scatter_task {
      input: in=filename, count=count
    }
  }
  call gather_task {
    input: count=count, word_lists=scatter_task.words
  }
}

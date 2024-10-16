esma_set_this()

set (alldirs
  )

esma_add_library (${this}
  SRCS 
  SUBCOMPONENTS ${alldirs}
  DEPENDENCIES MAPL esmf)


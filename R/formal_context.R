#' @export
#' @import scales RColorBrewer
formal_context <- R6::R6Class(

  classname = "FormalContext",

  public = list(

    I = NULL,

    attributes = NULL,

    objects = NULL,

    grades_set = NULL,

    concepts = NULL,

    implications = NULL,

    concept_support = NULL,

    implications_support = NULL,

    # Object constructor
    initialize = function(I,
                          grades_set = sort(unique(as.vector(I)))) {

      stopifnot(length(colnames(I)) == ncol(I))

      # Let us invent object names if not provided
      if (!(length(rownames(I)) == nrow(I))) {

        rownames(I) <- paste0(seq(nrow(I)))

      }

      # Transform the formal context to sparse
      self$I <- as(Matrix(t(I),
                          sparse = TRUE), "dgCMatrix")
      self$grades_set <- grades_set

      self$objects <- rownames(I)
      self$attributes <- colnames(I)

    },

    # Add a precomputed implication set
    add_implications = function(impl_set) {

      self$implications <- impl_set$clone()

    },

    # Use Ganter Algorithm to compute concepts
    compute_concepts = function(verbose = FALSE) {

      if (!is.null(self$concepts)) return(self$concepts)

      self$concepts <- .get_fuzzy_concepts_sparse(as.matrix(t(self$I)),
                                                  self$grades_set,
                                                  verbose = verbose)

      return(self$concepts)

    },

    # Use modified Ganter algorithm to compute both
    # concepts and implications
    extract_implications_concepts = function(verbose = FALSE) {

      c(concepts, implications) :=
        .get_concepts_implications_sparse(as.matrix(t(self$I)),
                                          self$grades_set,
                                          verbose = verbose)

      self$concepts <- concepts

      self$implications <- implications

    },

    # Plot the concept lattice
    plot_lattice = function() {

      if (length(self$concepts) > 0) {

        .draw_Hasse(self$concepts, as.matrix(self$I))

      }

    },

    # Plot the formal context table
    plot_context = function() {

      color_function <- colour_ramp(brewer.pal(11, "Greys"))
      heatmap(t(as.matrix(self$I)), Rowv = NA, Colv = NA,
              col = color_function(seq(0, 1, 0.01)),
              scale = "none")

    },

    # Get support of each concept
    get_concept_support = function() {

      my_I <- self$I
      my_I@x <- as.numeric(my_I@x)

      intents <- lapply(self$concepts, function(s) s[[2]])
      intents <- do.call(cbind, args = intents)

      subsets <- .is_subset_sparse(intents, my_I)

      self$concept_support <- rowMeans(subsets)

      return(self$concept_support)

    },

    # Compute support of each implication
    get_implication_support = function() {

      LHS <- self$implications$get_LHS_matrix()
      my_I <- self$I
      my_I@x <- as.numeric(my_I@x)

      subsets <- .is_subset_sparse(LHS, my_I)

      self$implications_support <- rowMeans(subsets)

      return(self$implications_support)

    }

  ),

  private = list(

    extents = NULL,

    intents = NULL
  )

)
# Sourced from Rprofile.site. RStudio builds the completion help popup for data
# frames and their columns by pasting data-derived text into HTML unescaped,
# and the IDE renders it with innerHTML. These wrappers escape that text.
#
# They wrap RStudio's internal .rs.* functions, so check them on every RStudio
# upgrade. If a function disappears, the session prints a warning instead of
# silently running unprotected.
local({
   wrap <- function(name, wrapper)
   {
      fullName <- paste0(".rs.", name)
      toolsEnv <- .rs.toolsEnv()
      if (!exists(fullName, envir = toolsEnv, inherits = FALSE))
      {
         warning("rstudio-hardening.R: ", fullName, " not found; completion help is not escaped")
         return(invisible())
      }
      # read into a local first: a lazy argument reading the binding after the
      # assign would find the wrapper and recurse
      original <- get(fullName, envir = toolsEnv)
      if (isTRUE(attr(original, "rstudio.hardened")))
         return(invisible())
      wrapped <- wrapper(original)
      attr(wrapped, "rstudio.hardened") <- TRUE
      assign(fullName, wrapped, envir = toolsEnv)
   }

   setHook("rstudio.sessionInit", function(...)
   {
      # html is "<h2></h2><h3>Description</h3><p>DESCRIPTION</p>", where
      # DESCRIPTION is str() output for the column's values
      wrap("getHelpColumnImpl", function(original) function(name, src, envir = parent.frame())
      {
         out <- original(name, src, envir)
         if (!is.list(out) || !is.character(out$html))
            return(out)

         prefix <- "<h2></h2><h3>Description</h3><p>"
         suffix <- "</p>"
         html <- out$html
         if (startsWith(html, prefix) && endsWith(html, suffix))
         {
            description <- substring(html, nchar(prefix) + 1L, nchar(html) - nchar(suffix))
            out$html <- paste0(prefix, .rs.htmlEscape(description), suffix)
         }
         else
         {
            # unknown layout: show it as text rather than render it
            out$html <- .rs.htmlEscape(html)
         }
         out
      })

      # the generated preamble starts "<h2>NAME</h2>"; real Rd help is left alone
      wrap("getHelpDataFrame", function(original) function(name, src, envir = parent.frame())
      {
         out <- original(name, src, envir)
         heading <- paste0("<h2>", name, "</h2>")
         if (is.list(out) && is.character(out$html) && startsWith(out$html, heading))
         {
            out$html <- paste0("<h2>", .rs.htmlEscape(name), "</h2>",
                               substring(out$html, nchar(heading) + 1L))
         }
         out
      })
   })
})

#!/usr/bin/env Rscript
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#Reading sas7bdat, searching and generate CSV file
#Using custom logger to output high-level structured log for audittrail
# 入力: <input.sas7bdat> <column_name> <search_value> <output_base> 
# 出力: <output_base>.csv（中間ファイル）
#
#History:
# 2026/05/03 Added comment
# 2026/05/05 Added comment
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

### Using Logger: Initialize ###
#if (!exists(".app_logger_initialized", inherits=TRUE)) {
#  try(.local_init_app_logger(), silent=TRUE)
#}
################################

### Using Logger: Start ###
#log_info("Script starts!!", action="script_start", user_id=uid, session_id=sid)
#log_info("Script starts!!", action="start")
message("[AEGIS Logging]Script Starts!")
###########################

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 5) {
  message("[AEGIS Logging]Usage: Rscript filter_sas_to_csv.R <input.sas7bdat> <column> <value> <output_base> <run_user>")
  
  ### Using Logger: Argument error ###
  #log_error("Invalid arguments", action="error", expected="input,column,value,output", got=args)
  ####################################
  quit(status=1)
}

in_path  <- args[1]; col <- args[2]; val <- args[3]; out_base <- args[4]; actual_executor <- args[5]
#========== Using followings in testing at console ============
#in_path <- "/studies/STD0001/s1reporting1_beatrice/01_input/ae.sas7bdat"
#col <- "AETERM"
#val <- "発熱"
#out_base <- "/studies/STD0001/s1reporting1_beatrice/02_output/fever"
#out_base <- "/studies/STD0001/s1reporting1_beatrice/02_output/fever.csv"
#actual_executor <- "Kitagawa, Atsushi:B06823"


### Using Logger: Arguments information ###
#log_info("Arguments detail", action="in_process", input=in_path, column=col, searchValue=val, output=out_base, run_user=actual_executor)
message(paste0("[AEGIS Logging]Arguments detail... input=",in_path,", column=",col,", searchValue=",val,", ouput=",out_base,", run_user=",actual_executor))
###########################################


req_pkgs <- c("haven", "dplyr", "readr")
missing <- req_pkgs[!req_pkgs %in% installed.packages()[, "Package"]]
if (length(missing) > 0) {
  renv::install(packages = missing)
}
#install.packages(c("haven","dplyr","readr"))

suppressPackageStartupMessages({
  library(haven); library(dplyr); library(readr)
})

#print(in_path)
#stopifnot(file.exists(in_path))
if(!file.exists(in_path)) {
  message("Caution: Input file does not exist")
  ### Using Logger: Argument error ###
  #log_error("Input not found", action="error", expected="Input must exist as an actual file", input=in_path)
  message("[AEGIS Logging]Input not found, input must exist as an actual file.")
  ####################################
  quit(status=2,save="no")
}


### Using Logger: Hash info for input file ###
#in_hash <- hash_file(in_path, "sha256")
#log_info("Confirm input file", action="in_process", path=in_path, sha256=in_hash)
in_hash <- digest::digest(file = in_path, algo = "sha256")
message(paste0("[AEGIS Logging]Confirm input file: ", in_path, ", Hash: ", in_hash))
##############################################

start1 <- Sys.time()

df <- read_sas(in_path)

# 文字列列を Shift_JIS とみなして UTF-8 に変換
# iconv で変換できない文字は NA にする（sub=""で除去することも可）
#df <- df %>%
#  mutate(across(
#    where(is.character),
#    ~ iconv(.x, from = "CP932", to = "UTF-8", sub = NA)
#  ))

#if (!col %in% names(df)) stop(sprintf("Column %s not found.", col))
if (!col %in% names(df)) {
  #stop(sprintf("Column %s not found.", col))
  message(sprintf("Caution: Column %s not found.", col))
  ### Using Logger: Argument error ###
  #log_error("Invalid column", action="error", msgtext="Designated column not found", column=col)
  message("[AEGIS Logging]Invalid column, designated column is not be found.")
  ####################################
  quit(status=3,save="no")
} 

trim_ws <- function(x) if (is.character(x)) trimws(x) else x
df <- df %>% mutate(across(where(is.character), trim_ws))

filtered <- df %>% filter(.data[[col]] == val)
#filtered <- df
cat(sprintf("Matched rows: %d\n", nrow(filtered)))
print(head(filtered, 50))

#out_csv <- paste0(out_base, ".csv")
out_csv <- out_base
dir.create(dirname(out_csv), showWarnings = FALSE, recursive = TRUE)
write_csv(filtered, out_csv, na = "")
cat(sprintf("Wrote CSV: %s\n", out_csv))

elapsed1_ms <- as.integer(difftime(Sys.time(), start1, units="secs")*1000)

if(!file.exists(out_csv)) {
  message("Caution: Output file does not exist")
  #log_error("Output not found", action="output_check", expected="Output must be generated as an actual csv file", output=out_csv)
  message("[AEGIS Logging]Output not found, output must be generated as an actual csv file.")
  quit(status=2,save="no")
}

### Using Logger: output hash ###
#out_hash <- hash_file(out_csv, "sha256")
out_hash <- digest::digest(file = out_csv, algo = "sha256")
#log_info("Output completed", action="in_process", path=out_csv, 
#         duration_ms=elapsed1_ms, sha256=out_hash, format="csv")
#log_info(sprintf("Output completed: path=%s, sha256=%s", out_csv, out_hash), action="in_process", path=out_csv, 
#         duration_ms=elapsed1_ms, sha256=out_hash, format="csv")
message(paste0("[AEGIS Logging]Output completed. output: ", out_csv, ", Hash: ", out_hash, ", Duration: ", elapsed1_ms))
#################################

source("test.R")

### Using Logger: End ###
#log_info("Script ends", action="script_end", user_id=uid, session_id=sid)
#log_info("Script ends", action="end")
message("[AEGIS Logging]Script ends")
#########################

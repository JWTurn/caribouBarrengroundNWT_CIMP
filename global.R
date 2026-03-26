repos <- c("https://predictiveecology.r-universe.dev", getOption("repos"))
source("https://raw.githubusercontent.com/PredictiveEcology/pemisc/refs/heads/development/R/getOrUpdatePkg.R")
getOrUpdatePkg(c("Require", "SpaDES.project"), c("1.0.1.9024", "1.0.1.9000")) # only install/update if required
#Require::Install("PredictiveEcology/SpaDES.core@development")

projPath = "~/git-local/caribouBarrengroundNWT_CIMP"
reproducibleInputsPath = "~/git-local/reproducibleInputs"
lapply(dir('R', '*.R', full.names = TRUE), source)

# make landStack since not module yet
landStack = makeBarrengroundLand(studyAreaLarge, inPath = reproducibleInputsPath, dPath = 'inputs') |>
  reproducible::Cache(.functionName = "landStack")
terra::writeRaster(landStack, file.path('inputs', 'landStack.tif'))

out <- SpaDES.project::setupProject(
  Restart = TRUE,
  useGit = 'JWTurn',
  updateRprofile = TRUE,
  #overwrite = TRUE,
  paths = list(projectPath =  projPath
               #"packagePath" = file.path("packages", Require:::versionMajorMinor())
  ),
  options = options(spades.allowInitDuringSimInit = TRUE,
                    spades.allowSequentialCaching = TRUE,
                    spades.moduleCodeChecks = FALSE,
                    spades.useRequire = TRUE, # try to fix packages
                    spades.recoveryMode = 1,
                    reproducible.inputPaths = reproducibleInputsPath,
                    reproducible.useMemoise = TRUE
                    ,reproducible.cloudFolderID = 'https://drive.google.com/drive/folders/1lDVP0G1FFft5WJgnKBLPPlkTXPsU04hr?usp=share_link'
  ),
  modules = c(
              'JWTurn/RSFpredict@main'

  ),
  params = list(
    .globals = list(
      .plots = c("png"),
      .studyAreaName=  "bathurst",
      outputFolderID = 'https://drive.google.com/drive/folders/1-OzIDz6azh39fcGsk5llZaGrqwvR-rBl?usp=share_link',
      .useCache = c(".inputObjects")
    )


  ),

  packages = c('RCurl', 'XML', 'snow', 'googledrive', 'httr2', "terra", "gert", "remotes", 'glmmTMB',
               "PredictiveEcology/reproducible@development", #"PredictiveEcology/LandR@development",
               "PredictiveEcology/SpaDES.core@development"),

  model = reproducible::prepInputs(url = 'https://drive.google.com/file/d/1HfMxbSrRUvpdL_R6OCHrVzh1Ce50rPrx/view?usp=share_link',
                                       fun = 'readRDS',
                                       destinationPath = 'inputs'),

  studyArea = reproducible::prepInputs(url = 'https://drive.google.com/file/d/1dIfh6_iK8mSmjhGJ56e0mz19q_fqgcAE/view?usp=share_link',
                                       fun =  'terra::vect',
                                       destinationPath = 'inputs',
                                       targetFile = 'Bathurst_Calving_MCP_females_only_2005_19.shp'),

  studyAreaLarge = terra::buffer(studyArea, 50000),

  landStack = terra::rast(file.path('inputs', 'landStack.tif'))

  # OUTPUTS TO SAVE -----------------------
  # outputs = {
  #   # save to disk 2 objects, every year
  #   #will add once works, ha
  #
  # }

)


results <- SpaDES.core::simInitAndSpades2(out)
results <- SpaDES.core::restartSpades()

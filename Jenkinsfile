@Library(["LibWithOTT", 'ArtToSVN'])

configuration = """
libraryTestSetup: RegressionTesting/Settings/libraryTestSetup.json

# Run on every commit

runConfigurations:


- kind: OCT-Linux:GCC-Experiments
  mtt: RegressionTesting/Settings/test_mtt_gcc.yaml
  releaseIniFiles: 
    - RegressionTesting/Settings/semla_release.yaml



"""

testToolWithGitlabConfiguration(configuration);

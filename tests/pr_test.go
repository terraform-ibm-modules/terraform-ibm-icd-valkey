// Tests in this file are run in the PR pipeline
package test

import (
	"context"
	"fmt"
	"log"
	"os"
	// "strings"
	"testing"
	// "sort"
	// "strconv"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const fullyConfigurableSolutionTerraformDir = "solutions/fully-configurable"

// const icdType = "valkey"
const icdShortType = "valkey"

// Use existing resource group
const resourceGroup = "geretain-test-valkey"

const basicExampleDir = "examples/basic"
const advancedExampleDir = "examples/advanced"

// Restricting due to limited availability of BYOK in certain regions
const regionSelectionPath = "../common-dev-assets/common-go-assets/icd-region-prefs.yaml"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

var sharedInfoSvc *cloudinfo.CloudInfoService

// Valkey Gen2 only supports private service endpoints, so tests must run via
// IBM Cloud Schematics (which executes inside IBM Cloud's network).

// GetRegionVersions is commented out because the /v5/ibm/deployables API does not list
// 'valkey' in classic ICD regions, and Gen2 region endpoints (ca-mon, in-che) are
// only reachable from within IBM Cloud's private network. Version validation is
// handled by the IBM provider at plan/apply time.
// For Valkey, version is hardcoded to "9.0" in tests.
//
// func GetRegionVersions(region string) (string, string) {

// 	cloudInfoSvc, err := cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{
// 		IcdRegion: region,
// 	})

// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	icdAvailableVersions, err := cloudInfoSvc.GetAvailableIcdVersions(icdType)

// 	if err != nil {
// 		log.Fatal(err)
// 	}

// 	if len(icdAvailableVersions) == 0 {
// 		log.Fatal("No available ICD versions found")
// 	}

// 	sort.Slice(icdAvailableVersions, func(i, j int) bool {
// 		partsI := strings.Split(icdAvailableVersions[i], ".")
// 		partsJ := strings.Split(icdAvailableVersions[j], ".")

// 		majorI, _ := strconv.Atoi(partsI[0])
// 		majorJ, _ := strconv.Atoi(partsJ[0])

// 		if majorI != majorJ {
// 			return majorI < majorJ
// 		}

// 		minorI := 0
// 		minorJ := 0

// 		if len(partsI) >= 2 {
// 			minorI, _ = strconv.Atoi(partsI[1])
// 		}
// 		if len(partsJ) >= 2 {
// 			minorJ, _ = strconv.Atoi(partsJ[1])
// 		}
// 		return minorI < minorJ
// 	})

// 	fmt.Println("version list is ", icdAvailableVersions)
// 	latestVersion := icdAvailableVersions[len(icdAvailableVersions)-1]
// 	oldestVersion := icdAvailableVersions[0]

// 	return latestVersion, oldestVersion
// }

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	var err error
	sharedInfoSvc, err = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})
	if err != nil {
		log.Fatal(err)
	}

	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, dir string) *testschematic.TestSchematicOptions {
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  prefix,
		TarIncludePatterns: []string{
			"*.tf",
			dir + "/*.tf",
		},
		TemplateFolder:         dir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 90,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
		{Name: "resource_group", Value: resourceGroup, DataType: "string"},
		{Name: "member_host_flavor", Value: "bx3d.4x20", DataType: "string"},
	}
	return options
}

func TestRunBasicExampleSchematics(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-basic", basicExampleDir)
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunAdvancedExampleSchematics(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-adv", advancedExampleDir)
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunUpgradeExampleSchematics(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-adv-upg", advancedExampleDir)
	options.CheckApplyResultForUpgrade = true

	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

// Test the fully-configurable DA with defaults (IBM owned encryption keys)
func TestRunFullyConfigurableSolutionSchematics(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableSolutionTerraformDir + "/*.tf",
		},
		TemplateFolder:             fullyConfigurableSolutionTerraformDir,
		BestRegionYAMLPath:         regionSelectionPath,
		Prefix:                     fmt.Sprintf("%s-fc-da", icdShortType),
		ResourceGroup:              resourceGroup,
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     60,
		CheckApplyResultForUpgrade: true,
	})

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-reader", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Viewer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Editor",
				},
			},
		},
	}

	serviceCredentialNames := []map[string]string{
		{
			"name":     "valkey-admin",
			"role":     "Administrator",
			"endpoint": "private",
		},
	}

	region := "us-south"
	// Note: Version hardcoded to 9.0 because icd-versions API doesn't list Valkey
	valkeyVersion := "9.0"
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "deletion_protection", Value: false, DataType: "bool"},
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "service_credential_names", Value: serviceCredentialNames, DataType: "list(object)"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "valkey_version", Value: valkeyVersion, DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

// Upgrade test the fully-configurable DA with KMS encryption (KYOK)
func TestRunFullyConfigurableWithKMSUpgradeSolution(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		TarIncludePatterns: []string{
			"*.tf",
			fullyConfigurableSolutionTerraformDir + "/*.tf",
		},
		TemplateFolder:             fullyConfigurableSolutionTerraformDir,
		Tags:                       []string{fmt.Sprintf("%s-fc-upg", icdShortType)},
		Prefix:                     fmt.Sprintf("%s-fc-upg", icdShortType),
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     120,
		CheckApplyResultForUpgrade: true,
	})

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-reader", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Viewer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Editor",
				},
			},
		},
	}

	resourceKeys := []map[string]string{
		{
			"name":     "admin",
			"role":     "Administrator",
			"endpoint": "private",
		},
		{
			"name":     "user1",
			"role":     "Viewer",
			"endpoint": "private",
		},
		{
			"name":     "user2",
			"role":     "Editor",
			"endpoint": "private",
		},
	}

	region := "us-south"
	// Note: Version hardcoded to 9.0 because icd-versions API doesn't list Valkey
	valkeyVersion := "9.0"
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "deletion_protection", Value: false, DataType: "bool"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "service_credential_names", Value: resourceKeys, DataType: "list(object)"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "valkey_version", Value: valkeyVersion, DataType: "string"},
	}
	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

func TestPlanValidation(t *testing.T) {
	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: fullyConfigurableSolutionTerraformDir,
		Prefix:       "val-plan",
		Region:       "us-south",
	})
	options.TestSetup()
	options.TerraformOptions.NoColor = true
	options.TerraformOptions.Logger = logger.Discard

	// Note: Version hardcoded to 9.0 because icd-versions API doesn't list Valkey
	valkeyVersion := "9.0"
	options.TerraformOptions.Vars = map[string]interface{}{
		"prefix":                       options.Prefix,
		"region":                       "us-south",
		"valkey_version":               valkeyVersion,
		"provider_visibility":          "private", // Valkey only supports private endpoints
		"existing_resource_group_name": resourceGroup,
	}

	// Test the DA when using an existing KMS instance
	var fullyConfigurableWithExistingKms = map[string]interface{}{
		"access_tags":               permanentResources["accessTags"],
		"existing_kms_instance_crn": permanentResources["hpcs_south_crn"],
		"kms_encryption_enabled":    true,
	}

	// Test the DA when using IBM owned encryption key
	var fullyConfigurableWithIbmOwnedKey = map[string]interface{}{
		"kms_encryption_enabled": false,
	}

	// Create a map of the variables
	tfVarsMap := map[string]map[string]interface{}{
		"fullyConfigurableWithExistingKms": fullyConfigurableWithExistingKms,
		"fullyConfigurableWithIbmOwnedKey": fullyConfigurableWithIbmOwnedKey,
	}

	_, initErr := terraform.InitContextE(t, context.Background(), options.TerraformOptions)
	if assert.Nil(t, initErr, "This should not have errored") {
		// Iterate over the slice of maps
		for name, tfVars := range tfVarsMap {
			t.Run(name, func(t *testing.T) {
				// Iterate over the keys and values in each map
				for key, value := range tfVars {
					options.TerraformOptions.Vars[key] = value
				}
				output, err := terraform.PlanContextE(t, context.Background(), options.TerraformOptions)
				assert.Nil(t, err, "This should not have errored")
				assert.NotNil(t, output, "Expected some output")
				// Delete the keys from the map
				for key := range tfVars {
					delete(options.TerraformOptions.Vars, key)
				}
			})
		}
	}
}

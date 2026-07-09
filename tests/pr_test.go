// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"context"
	"fmt"
	"log"
	"os"
	"sort"
	"strconv"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-valkey"

const icdShortType = "valk"

const basicExampleDir = "examples/basic"
const advancedExampleDir = "examples/advanced"
const fullyConfigurableSolutionTerraformDir = "solutions/fully-configurable"

// Restricting due to limited availability of BYOK in certain regions
const regionSelectionPath = "../common-dev-assets/common-go-assets/icd-region-prefs.yaml"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

var sharedInfoSvc *cloudinfo.CloudInfoService

// Valkey Gen2 only supports private service endpoints
func GetRegionVersions(region string) (string, string) {

	cloudInfoSvc, err := cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{
		IcdRegion: region,
	})

	if err != nil {
		log.Fatal(err)
	}

	icdAvailableVersions, err := cloudInfoSvc.GetAvailableIcdVersionsGen2("databases-for-valkey", "standard-gen2", region) // this function takes service, plan and region as arguments in this specific order

	if err != nil {
		log.Fatal(err)
	}

	if len(icdAvailableVersions) == 0 {
		log.Fatal("No available ICD versions found")
	}

	sort.Slice(icdAvailableVersions, func(i, j int) bool {
		partsI := strings.Split(icdAvailableVersions[i], ".")
		partsJ := strings.Split(icdAvailableVersions[j], ".")

		majorI, _ := strconv.Atoi(partsI[0])
		majorJ, _ := strconv.Atoi(partsJ[0])

		if majorI != majorJ {
			return majorI < majorJ
		}

		minorI := 0
		minorJ := 0

		if len(partsI) >= 2 {
			minorI, _ = strconv.Atoi(partsI[1])
		}
		if len(partsJ) >= 2 {
			minorJ, _ = strconv.Atoi(partsJ[1])
		}
		return minorI < minorJ
	})

	fmt.Println("version list is ", icdAvailableVersions)
	latestVersion := icdAvailableVersions[len(icdAvailableVersions)-1]
	oldestVersion := icdAvailableVersions[0]

	return latestVersion, oldestVersion
}

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		Region:        "eu-de", // Currently, Valkey is supported only in the eu-de region.
		ResourceGroup: resourceGroup,
	})
	return options
}

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

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-basic", basicExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-adv", advancedExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test (using advanced example)
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-adv-upg", advancedExampleDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestPlanValidation(t *testing.T) {
	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: fullyConfigurableSolutionTerraformDir,
		Prefix:       "val-plan",
		Region:       "eu-de", // Currently, Valkey is supported only in the eu-de region.
	})
	options.TestSetup()
	options.TerraformOptions.NoColor = true
	options.TerraformOptions.Logger = logger.Discard

	region := options.Region
	valkeyVersion, _ := GetRegionVersions(region)
	options.TerraformOptions.Vars = map[string]interface{}{
		"prefix":                       options.Prefix,
		"region":                       region,
		"valkey_version":               valkeyVersion,
		"provider_visibility":          "public",
		"existing_resource_group_name": resourceGroup,
	}

	// Test the DA when using an existing KMS instance
	var fullyConfigurableWithExistingKms = map[string]interface{}{
		"access_tags":               permanentResources["accessTags"],
		"existing_kms_instance_crn": permanentResources["kp_dedicated_us_south_crn"],
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

	uniqueResourceGroup := generateUniqueResourceGroupName(options.Prefix)

	serviceCredentialSecrets := []map[string]interface{}{
		{
			"secret_group_name": fmt.Sprintf("%s-secret-group", options.Prefix),
			"service_credentials": []map[string]string{
				{
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Writer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-manager", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Manager",
				},
			},
		},
	}

	serviceCredentialNames := []map[string]string{
		{
			"name":     "valkey-writer",
			"role":     "Writer",
			"endpoint": "private",
		},
		{
			"name":     "valkey-manager",
			"role":     "Manager",
			"endpoint": "private",
		},
	}

	region := "eu-de" // Currently, Valkey is supported only in the eu-de region.
	valkeyVersion, _ := GetRegionVersions(region)
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "deletion_protection", Value: false, DataType: "bool"},
		{Name: "existing_resource_group_name", Value: uniqueResourceGroup, DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "service_credential_names", Value: serviceCredentialNames, DataType: "list(object)"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["kp_dedicated_us_south_crn"], DataType: "string"},
		{Name: "kms_endpoint_type", Value: "private", DataType: "string"},
		{Name: "valkey_version", Value: valkeyVersion, DataType: "string"},
	}

	err := sharedInfoSvc.WithNewResourceGroup(uniqueResourceGroup, func() error {
		return options.RunSchematicTest()
	})
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
					"secret_name": fmt.Sprintf("%s-cred-writer", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Writer",
				},
				{
					"secret_name": fmt.Sprintf("%s-cred-manager", options.Prefix),
					"service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::role:Manager",
				},
			},
		},
	}

	resourceKeys := []map[string]string{
		{
			"name":     "manager",
			"role":     "Manager",
			"endpoint": "private",
		},
		{
			"name":     "user1",
			"role":     "Writer",
			"endpoint": "private",
		},
	}

	uniqueResourceGroup := generateUniqueResourceGroupName(options.Prefix)

	region := "eu-de"
	valkeyVersion, _ := GetRegionVersions(region)
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "deletion_protection", Value: false, DataType: "bool"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "existing_resource_group_name", Value: uniqueResourceGroup, DataType: "string"},
		{Name: "service_credential_names", Value: resourceKeys, DataType: "list(object)"},
		{Name: "service_credential_secrets", Value: serviceCredentialSecrets, DataType: "list(object)"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
		{Name: "kms_encryption_enabled", Value: true, DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["kp_dedicated_us_south_crn"], DataType: "string"},
		{Name: "valkey_version", Value: valkeyVersion, DataType: "string"},
	}
	err := sharedInfoSvc.WithNewResourceGroup(uniqueResourceGroup, func() error {
		return options.RunSchematicUpgradeTest()
	})
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}

func generateUniqueResourceGroupName(baseName string) string {
	id := uuid.New().String()[:8] // Shorten UUID for readability
	return fmt.Sprintf("%s-%s", baseName, id)
}

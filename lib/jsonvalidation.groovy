import groovy.json.JsonSlurper

def validateJsonStructure(jsonDir) {
    def dir = file(jsonDir)
    def jsonSlurper = new JsonSlurper()
    def nameToFilesList = [:]
    def filesWithoutName = []
    def invalidJsonFiles = []
    
    // Get all JSON files
    def jsonFiles = dir.listFiles().findAll { it.name.endsWith('.json') }
    
    if (jsonFiles.isEmpty()) {
        error "No JSON files found in directory: ${jsonDir}"
    }
    
    log.info "Validating JSON structure for ${jsonFiles.size()} files..."
    
    // Process each JSON file
    jsonFiles.each { jsonFile ->
        try {
            def jsonContent = jsonSlurper.parse(jsonFile)
            
            // Check if 'name' field exists
            if (!jsonContent.containsKey('name')) {
                filesWithoutName.add(jsonFile.name)
                return
            }
            
            def nameValue = jsonContent.name
            
            // Check if name is null or empty
            if (nameValue == null || (nameValue instanceof String && nameValue.trim().isEmpty())) {
                filesWithoutName.add(jsonFile.name)
                return
            }
            
            def nameStr = nameValue.toString()
            
            // Track all files for each name
            if (!nameToFilesList.containsKey(nameStr)) {
                nameToFilesList[nameStr] = []
            }
            nameToFilesList[nameStr].add(jsonFile.name)
            
        } catch (Exception e) {
            invalidJsonFiles.add([
                file: jsonFile.name,
                error: e.message
            ])
        }
    }
    
    // Find duplicates (names that appear in more than one file)
    def duplicateNames = nameToFilesList.findAll { name, files -> files.size() > 1 }
    
    // Report validation results
    def hasErrors = false
    
    if (!invalidJsonFiles.isEmpty()) {
        hasErrors = true
        log.error "Invalid JSON files found:"
        invalidJsonFiles.each { 
            log.error "  - ${it.file}: ${it.error}"
        }
    }
    
    if (!filesWithoutName.isEmpty()) {
        hasErrors = true
        log.error "JSON files missing 'name' field or have empty/null names:"
        filesWithoutName.each { 
            log.error "  - ${it}"
        }
    }
    
    if (!duplicateNames.isEmpty()) {
        hasErrors = true
        def duplicateMessage = "Duplicate 'name' values found:\n" + 
            duplicateNames.collect { name, files ->
                "  - Name '${name}' appears in ${files.size()} files: ${files.join(', ')}"
            }.join('\n')
        log.error duplicateMessage
    }
    
    if (hasErrors) {
        error "JSON validation failed. Please fix the above issues and try again."
    }
    
    // Convert to single file mapping for return (using first occurrence)
    def nameToFileMap = nameToFilesList.collectEntries { name, files -> 
        [name, files[0]] 
    }
    
    log.info "✓ JSON structure validation passed: ${nameToFileMap.size()} unique names found"
    return nameToFileMap
}
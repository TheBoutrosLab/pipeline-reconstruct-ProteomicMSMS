import java.nio.charset.StandardCharsets
import java.nio.file.Files

/** Expand environment variables in CSV inputs used by nf-test. */
class NFTestCsvTools {
    /** Expand $NAME and ${NAME}, failing when a referenced variable is undefined. */
    String expandEnvironmentVariables(String content) {
        if (content == null) {
            return null
        }

        def variablePattern = ~/\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))/
        content.replaceAll(variablePattern) { match, bracedName, bareName ->
            def variableName = bracedName ?: bareName
            def variableValue = System.getenv(variableName)
            if (variableValue == null) {
                throw new IllegalArgumentException(
                    "Environment variable ${variableName} referenced by test input is not defined"
                )
            }
            variableValue
        }
    }

    /** Write an expanded copy beneath the nf-test work directory. */
    String prepareInputCsv(Object sourceCsv, String testName, Object launchDir) {
        def sourceFile = new File(sourceCsv.toString())
        if (!sourceFile.isFile()) {
            throw new IllegalArgumentException("Test input CSV does not exist: ${sourceFile}")
        }

        def workRoot = new File(System.getenv('NXF_WORK') ?: "${launchDir}/work")
        def inputDirectory = new File(workRoot, 'nftest-input')
        Files.createDirectories(inputDirectory.toPath())

        def safeTestName = testName.replaceAll(/[^A-Za-z0-9_.-]/, '-')
        def expandedCsv = File.createTempFile("${safeTestName}-", '.csv', inputDirectory)
        def sourceContent = Files.readString(sourceFile.toPath(), StandardCharsets.UTF_8)
        Files.writeString(
            expandedCsv.toPath(),
            expandEnvironmentVariables(sourceContent),
            StandardCharsets.UTF_8
        )
        expandedCsv.absolutePath
    }
}

return new NFTestCsvTools()

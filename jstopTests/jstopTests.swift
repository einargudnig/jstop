import XCTest
@testable import jstop

@MainActor
final class ParseEtimeTests: XCTestCase {
    func testMinutesAndSeconds() {
        XCTAssertEqual(ProcessManager.parseEtime("05:03"), 303)
    }

    func testHoursMinutesSeconds() {
        XCTAssertEqual(ProcessManager.parseEtime("1:23:45"), 5025)
    }

    func testDaysHoursMinutesSeconds() {
        XCTAssertEqual(ProcessManager.parseEtime("2-10:30:00"), 210600)
    }

    func testZero() {
        XCTAssertEqual(ProcessManager.parseEtime("00:00"), 0)
    }

    func testOneDayZeroTime() {
        XCTAssertEqual(ProcessManager.parseEtime("1-00:00:00"), 86400)
    }
}

@MainActor
final class BasenameTests: XCTestCase {
    func testFullPath() {
        XCTAssertEqual(ProcessManager.basename("/usr/local/bin/node"), "node")
    }

    func testPlainName() {
        XCTAssertEqual(ProcessManager.basename("node"), "node")
    }

    func testTrailingSlash() {
        XCTAssertEqual(ProcessManager.basename("/usr/bin/"), "")
    }

    func testFnmPath() {
        XCTAssertEqual(
            ProcessManager.basename("/Users/me/.local/state/fnm_multishells/123/bin/node"),
            "node"
        )
    }
}

final class ExtractShortPathTests: XCTestCase {
    func testNodeModulesPath() {
        let result = JSProcess.extractShortPath(
            from: "node /Users/me/work/my-app/node_modules/.bin/vite dev"
        )
        XCTAssertEqual(result, "me/work/my-app")
    }

    func testNpxPath() {
        let result = JSProcess.extractShortPath(
            from: "node /Users/me/.npm/_npx/abc123/playwright-mcp"
        )
        XCTAssertEqual(result, "_npx/abc123/playwright-mcp")
    }

    func testNoPathArgs() {
        let result = JSProcess.extractShortPath(from: "node server.js --port 3000")
        XCTAssertEqual(result, "server.js --port 3000")
    }
}

final class DetectFrameworkTests: XCTestCase {
    func testNextJs() {
        let result = JSProcess.detectFramework(
            from: ["node /Users/me/app/node_modules/.bin/next dev"],
            runtime: "node"
        )
        XCTAssertEqual(result, "Next.js")
    }

    func testVite() {
        let result = JSProcess.detectFramework(
            from: ["node /Users/me/app/node_modules/.bin/vite dev"],
            runtime: "node"
        )
        XCTAssertEqual(result, "Vite")
    }

    func testFallbackToRuntime() {
        let result = JSProcess.detectFramework(
            from: ["node /Users/me/app/server.js"],
            runtime: "node"
        )
        XCTAssertEqual(result, "node")
    }

    func testDescendantArgs() {
        let result = JSProcess.detectFramework(
            from: ["bun dev", "node /app/node_modules/.bin/next dev"],
            runtime: "bun"
        )
        XCTAssertEqual(result, "Next.js")
    }

    func testRemix() {
        let result = JSProcess.detectFramework(
            from: ["node /app/node_modules/.bin/remix dev"],
            runtime: "node"
        )
        XCTAssertEqual(result, "Remix")
    }
}

final class JSProcessUptimeStringTests: XCTestCase {
    private func makeProcess(uptime: TimeInterval) -> JSProcess {
        JSProcess(id: 1, pid: 1, name: "node", args: "", ports: [], uptime: uptime)
    }

    func testSeconds() {
        XCTAssertEqual(makeProcess(uptime: 45).uptimeString, "45s")
    }

    func testMinutes() {
        XCTAssertEqual(makeProcess(uptime: 300).uptimeString, "5m")
    }

    func testHoursAndMinutes() {
        XCTAssertEqual(makeProcess(uptime: 8100).uptimeString, "2h 15m")
    }

    func testDaysAndHours() {
        XCTAssertEqual(makeProcess(uptime: 97200).uptimeString, "1d 3h")
    }
}

import { execFile, spawn } from "node:child_process";
import { clean } from "./text.ts";

export class PickerError extends Error {}
export interface CommandOptions {
  input?: string;
  timeout?: number;
  optional?: boolean;
  cancel?: boolean;
  signal?: AbortSignal;
}
export interface CommandResult {
  code: number | null;
  stdout: string;
  stderr: string;
  error?: Error;
}
export interface LaunchOptions {
  cwd?: string;
  env: NodeJS.ProcessEnv;
  detached: boolean;
}
export interface RunningCommand {
  poll(): { code: number | null; error?: Error } | undefined;
  wait(): Promise<{ code: number | null; error?: Error }>;
  release(): void;
}

// This boundary lets fixtures replace all terminal/desktop commands, not Git or fzf parsing.
export const commands = {
  capture(
    args: string[],
    options: CommandOptions = {},
  ): Promise<CommandResult> {
    return new Promise((done, reject) => {
      const child = execFile(
        args[0],
        args.slice(1),
        {
          encoding: "utf8",
          timeout: options.timeout ?? 5000,
          maxBuffer: 16 * 1024 * 1024,
          signal: options.signal,
        },
        (error, stdout, stderr) => {
          process.off("SIGINT", onInterrupt);
          done({
            code: error
              ? typeof error.code === "number"
                ? error.code
                : null
              : 0,
            stdout,
            stderr,
            error: error && typeof error.code !== "number" ? error : undefined,
          });
        },
      );
      const onInterrupt = () => {
        child.kill("SIGINT");
      };
      process.once("SIGINT", onInterrupt);
      child.stdin?.on("error", (error: NodeJS.ErrnoException) => {
        // fzf may close its input early when the user accepts or cancels.
        if (error.code !== "EPIPE") reject(error);
      });
      child.stdin?.end(options.input ?? "");
    });
  },
  launch(args: string[], options: LaunchOptions): RunningCommand {
    const child = spawn(args[0], args.slice(1), {
      ...options,
      stdio: "inherit",
    });
    let result: { code: number | null; error?: Error } | undefined;
    const finished = new Promise<{ code: number | null; error?: Error }>(
      (done) => {
        child.once("error", (error) => {
          result = { code: null, error };
          done(result);
        });
        child.once("exit", (code) => {
          result = { code };
          done(result);
        });
      },
    );
    return {
      poll: () => result,
      wait: () => finished,
      release: () => child.unref(),
    };
  },
};

export async function run(
  args: string[],
  options: CommandOptions = {},
): Promise<string | null> {
  const result = await commands.capture(args, options);
  if (result.error || result.code !== 0) {
    if (
      options.optional ||
      (!result.error && options.cancel && [1, 130].includes(result.code!))
    )
      return null;
    throw new PickerError(
      clean(
        result.error?.message ||
          result.stderr.trim() ||
          `${args[0]} exited ${result.code}`,
      ),
    );
  }
  return result.stdout;
}

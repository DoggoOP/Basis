import SwiftUI

struct ExploreHomeView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 32) {
        header
        NavigationLink(value: Route.demo) {
          Label("Start Demo", systemImage: "play.fill")
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        VStack(alignment: .leading, spacing: 12) {
          Text("Explore")
            .font(.title2.weight(.bold))
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
            ForEach(Lab.allCases) { lab in
              NavigationLink(value: Route.lab(lab)) {
                LabCard(lab: lab)
              }
              .buttonStyle(.plain)
            }
          }
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("Tools")
            .font(.title2.weight(.bold))
          NavigationLink(value: Route.probe) {
            ToolRow(
              title: "Use This iPhone as a Probe",
              detail: "Stream a real 3D vector into Coordinates",
              systemImage: "iphone.radiowaves.left.and.right"
            )
          }
          .buttonStyle(.plain)
          NavigationLink(value: Route.calibration) {
            ToolRow(
              title: "Hinge Calibration",
              detail: "Verify the device's angle convention",
              systemImage: "angle"
            )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(24)
      .frame(maxWidth: 900)
      .frame(maxWidth: .infinity)
    }
    .background(Theme.background.ignoresSafeArea())
    .navigationTitle("Basis")
    .toolbarTitleDisplayMode(.inlineLarge)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Math you can hold.")
        .font(.system(.largeTitle, design: .serif).italic())
        .foregroundStyle(Theme.neutral)
      Text("Two real planes, one real line of intersection, one measurable angle. The phone is the matrix.")
        .font(.body)
        .foregroundStyle(.secondary)
    }
  }
}

private struct LabCard: View {
  var lab: Lab

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: lab.systemImage)
        .font(.title2)
        .foregroundStyle(Theme.hinge)
        .frame(width: 36)
      VStack(alignment: .leading, spacing: 4) {
        Text(lab.title)
          .font(.headline)
          .textCase(.uppercase)
          .tracking(1)
          .foregroundStyle(Theme.neutral)
        Text(lab.subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(18)
    .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
    .background(Theme.spine, in: .rect(cornerRadius: 20))
    .contentShape(.rect(cornerRadius: 20))
  }
}

private struct ToolRow: View {
  var title: String
  var detail: String
  var systemImage: String

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: systemImage)
        .font(.title3)
        .foregroundStyle(Theme.probe)
        .frame(width: 36)
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.headline)
        Text(detail).font(.subheadline).foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
      Image(systemName: "chevron.forward")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(16)
    .background(Theme.spine, in: .rect(cornerRadius: 16))
    .contentShape(.rect(cornerRadius: 16))
  }
}
